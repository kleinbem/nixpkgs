{
  lib,
  buildMozillaMach,
  fetchurl,
  nixosTests,
  zstd,
}:

let
  sources = lib.importJSON ./sources.json;
  inherit (sources) version firefoxVersion;
in
(buildMozillaMach {
  pname = "zen-browser";
  packageVersion = version;
  version = firefoxVersion;
  applicationName = "zen";
  binaryName = "zen";
  branding = "browser/branding/release";

  # The source snapshot upstream publishes with every release: Firefox with Zen's
  # patches and sources already applied, as its own release binaries were built from.
  # The git tag is not that: it can point at later commits than the release build.
  src = fetchurl {
    url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.source.tar.zst";
    inherit (sources) hash;
  };

  # The archive has no top-level directory.
  unpackPhase = ''
    runHook preUnpack
    mkdir source
    tar --use-compress-program=zstd -xf $src -C source
    cd source
    runHook postUnpack
  '';

  extraNativeBuildInputs = [ zstd ];

  # Upstream's build tool writes the Zen version here before it calls mach.
  extraPostPatch = ''
    printf %s ${lib.escapeShellArg version} > browser/config/version.txt
    printf %s ${lib.escapeShellArg version} > browser/config/version_display.txt
  '';

  extraConfigureFlags = [
    "--with-app-basename=Zen"
    "--enable-update-channel=release"
    "--with-unsigned-addon-scopes=app,system"
  ];

  extraPreConfigure = ''
    # Shown in the About dialog.
    export ZEN_FIREFOX_VERSION=${lib.escapeShellArg firefoxVersion}
    # Upstream builds without telemetry; official branding would turn it on.
    export MOZ_TELEMETRY_REPORTING=
  '';

  tests = { inherit (nixosTests) zen-browser; };
  updateScript = ./update.sh;

  meta = {
    description = "Firefox based browser with a focus on privacy and customization";
    homepage = "https://zen-browser.app";
    downloadPage = "https://zen-browser.app/download";
    changelog = "https://zen-browser.app/release-notes/#${version}";
    maintainers = with lib.maintainers; [
      matthewpi
      titaniumtown
      eveeifyeve
      _0x4bs3nt
    ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maxSilent = 14400; # 4h, double the default of 7200s (c.f. #129212, #129115)
    license = lib.licenses.mpl20;
    mainProgram = "zen";
  };
}).override
  {
    enableAddonSigning = false;
    enableAddonSideload = true;
    enableCrashReporter = false;
    enableOfficialBranding = true;
  }
