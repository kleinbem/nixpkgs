{
  lib,
  rustPlatform,
  buildPackages,
  cacert,
  cmake,
  makeBinaryWrapper,
  pkg-config,
  versionCheckHook,
  mesh-llm,
  skippy-native-runtime,

  config,
  cudaSupport ? config.cudaSupport,
  rocmSupport ? config.rocmSupport,
}:

let
  # The same runtime bundles and environment as mesh-llm, which loads the same runtime.
  inherit (mesh-llm.override { inherit cudaSupport rocmSupport; })
    runtimeEnvironment
    runtimePrograms
    ;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "skippy";

  __structuredAttrs = true;
  strictDeps = true;
  # Skippy is released with MeshLLM, from the same source and tag.
  inherit (skippy-native-runtime) version;
  src = skippy-native-runtime.meshLlmSrc;
  inherit (mesh-llm) cargoDeps;

  cargoBuildFlags = [
    "--package"
    "skippy-cli"
    "--bin"
    "skippy"
  ];
  cargoTestFlags = [
    "--package"
    "skippy-cli"
  ];
  # Load the runtime from a bundle instead of linking llama.cpp statically.
  buildFeatures = [ "dynamic-native-runtime" ];

  nativeBuildInputs = [
    cmake
    makeBinaryWrapper
    pkg-config
  ];

  # Serve tests build an HTTPS client, which loads the CA bundle.
  nativeCheckInputs = [ cacert ];

  inherit (mesh-llm) postPatch env;

  # cmake is only used by dependency build scripts
  dontUseCmakeConfigure = true;

  postInstall = ''
    wrapProgram $out/bin/skippy ${
      lib.escapeShellArgs (
        lib.concatLists (
          lib.mapAttrsToList (name: value: [
            "--set-default"
            name
            value
          ]) runtimeEnvironment
        )
        ++ lib.optionals (runtimePrograms != [ ]) [
          "--prefix"
          "PATH"
          ":"
          (lib.makeBinPath runtimePrograms)
        ]
      )
    }
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  inherit (mesh-llm) preVersionCheck;

  meta = {
    description = "Serve a language model locally behind OpenAI- and Anthropic-compatible APIs";
    longDescription = ''
      Skippy is the model-serving engine of MeshLLM, usable on its own: it
      downloads models, sizes the context to the available memory and serves
      one model on this machine. This package bundles the same runtimes as
      mesh-llm (CPU and, on Linux, Vulkan; CUDA and ROCm with the nixpkgs
      settings `cudaSupport` and `rocmSupport`).
    '';
    homepage = "https://github.com/Mesh-LLM/mesh-llm/tree/main/skippy";
    changelog = "https://github.com/Mesh-LLM/mesh-llm/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ kleinbem ];
    mainProgram = "skippy";
    inherit (skippy-native-runtime.meta) platforms;
  };
})
