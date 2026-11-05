{
  lib,
  stdenv,
  rustPlatform,
  aws-lc,
  pkg-config,
  sqlite,
  nodejs,
  mesh-llm,
  skippy-native-runtime,
}:

# nixpkgs-update: no auto update
# mesh-llm's update script updates the release.
rustPlatform.buildRustPackage {
  pname = "mesh-llm-nodejs";

  __structuredAttrs = true;
  strictDeps = true;

  inherit (skippy-native-runtime) version;
  src = skippy-native-runtime.meshLlmSrc;
  inherit (mesh-llm) cargoDeps postPatch env;

  cargoBuildFlags = [
    "--package"
    "mesh-llm-nodejs"
  ];

  cargoTestFlags = [
    "--package"
    "mesh-llm-nodejs"
  ];

  nativeBuildInputs = [
    pkg-config
    nodejs
  ];

  # Found through pkg-config by aws-lc-sys and rusqlite's libsqlite3-sys.
  buildInputs = [
    aws-lc
    sqlite
  ];

  installPhase = ''
    runHook preInstall
    sdk=$out/lib/node_modules/@mesh-llm/sdk
    mkdir -p $sdk/native
    # What package.json's "files" publishes, without console/: the release puts a
    # prebuilt web console there, which nothing in the SDK reads.
    (cd mesh/sdk/node && cp -r index.js index.d.ts inference.js models.js \
      live-transcription.js memberships.js native-runtime.js README.md $sdk/)
    install -Dm755 target/*/release/libmesh_llm_nodejs${stdenv.hostPlatform.extensions.sharedLibrary} \
      $sdk/native/mesh_llm_nodejs.node
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    node -e 'const sdk = require(process.argv[1]); if (!sdk.Node) process.exit(1);' \
      $out/lib/node_modules/@mesh-llm/sdk
    runHook postInstallCheck
  '';

  meta = {
    description = "Node.js and TypeScript SDK with the native addon for MeshLLM";
    homepage = "https://github.com/Mesh-LLM/mesh-llm/tree/main/mesh/sdk/node";
    inherit (skippy-native-runtime.meta) changelog;
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ kleinbem ];
    inherit (skippy-native-runtime.meta) platforms;
  };
}
