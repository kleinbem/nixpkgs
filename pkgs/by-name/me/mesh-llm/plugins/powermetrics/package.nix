{
  lib,
  rustPlatform,
  fetchFromGitHub,
  buildPackages,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "mesh-llm-powermetrics-plugin";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "Mesh-LLM";
    repo = "powermetrics-plugin";
    tag = "v${finalAttrs.version}";
    hash = "sha256-DrVyaLN2DgIaWP9WP0102x0yHIG53vAZlmVCoH7lMq8=";
  };

  cargoHash = "sha256-euAUtpXrFBDj5szOk8CIZxjcp2ekspIfCRYEpwEXDHc=";

  __structuredAttrs = true;
  strictDeps = true;

  # Otherwise mesh-llm-plugin's build script runs a prebuilt protoc.
  env.PROTOC = lib.getExe' buildPackages.protobuf "protoc";

  passthru = {
    # The name the plugin reports to the host, which must match its [[plugin]] entry.
    pluginName = "powermetrics-plugin";
  };

  meta = {
    description = "Energy per output token from GPU power and local inference plugin for MeshLLM";
    homepage = "https://github.com/Mesh-LLM/powermetrics-plugin";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ kleinbem ];
    mainProgram = "powermetrics-plugin";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
