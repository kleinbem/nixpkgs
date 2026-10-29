# Trial only (not part of the PR): runs Berd's voice stack against nixpkgs' shared sherpa-onnx
# and onnxruntime with the pinned upstream models.
{
  lib,
  stdenv,
  berd,
  fetchurl,
  runCommand,
}:

let
  rustTarget = stdenv.hostPlatform.rust.rustcTarget;

  # src-tauri/crates/berd-voice/src/parakeet_assets.rs
  parakeetModel =
    runCommand "berd-parakeet-model"
      {
        src = fetchurl {
          url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-parakeet_tdt_ctc_110m-en-36000-int8.tar.bz2";
          sha256 = "17f945007b52ccd8b7200ffc7c5652e9e8e961dfdf479cefcabd06cf5703630b";
        };
      }
      ''
        tar xjf $src
        mkdir $out
        cp sherpa-onnx-nemo-parakeet_tdt_ctc_110m-en-36000-int8/{model.int8.onnx,tokens.txt} $out/
      '';

  # src-tauri/crates/berd-voice/src/pocket_assets.rs
  pocketFiles = [
    { path = "bundle.json"; sha256 = "bab643150f437f37df080a710520ff39ed9ebd9a339f8ebdc739f7eddfc28b3f"; url = "https://huggingface.co/KevinAHM/pocket-tts-onnx/resolve/58a6d00cf13d239b6748cb0769f35c580a8f606c/onnx/english_2026-04/bundle.json"; }
    { path = "bos_before_voice.npy"; sha256 = "f46edf4f7007b7ba4ea58831f49d003e59e167b4641c44bb3addfe9231a780b1"; url = "https://huggingface.co/KevinAHM/pocket-tts-onnx/resolve/58a6d00cf13d239b6748cb0769f35c580a8f606c/onnx/english_2026-04/bos_before_voice.npy"; }
    { path = "tokenizer.model"; sha256 = "d461765ae179566678c93091c5fa6f2984c31bbe990bf1aa62d92c64d91bc3f6"; url = "https://huggingface.co/KevinAHM/pocket-tts-onnx/resolve/58a6d00cf13d239b6748cb0769f35c580a8f606c/onnx/english_2026-04/tokenizer.model"; }
    { path = "flow_lm_main_int8.onnx"; sha256 = "f9bd8106b79a0192c1c43399ab938fb24900a95c1c599870d75a884e99000116"; url = "https://huggingface.co/KevinAHM/pocket-tts-onnx/resolve/58a6d00cf13d239b6748cb0769f35c580a8f606c/onnx/english_2026-04/flow_lm_main_int8.onnx"; }
    { path = "flow_lm_flow_int8.onnx"; sha256 = "3dd781ee5abee9e195320bf0106bebd6372a852b3b36352524ee78b40554635d"; url = "https://huggingface.co/KevinAHM/pocket-tts-onnx/resolve/58a6d00cf13d239b6748cb0769f35c580a8f606c/onnx/english_2026-04/flow_lm_flow_int8.onnx"; }
    { path = "mimi_decoder_int8.onnx"; sha256 = "3630450a3297a101792a6ac66619ebc70ab916b265e6220c2afaef8b1673f925"; url = "https://huggingface.co/KevinAHM/pocket-tts-onnx/resolve/58a6d00cf13d239b6748cb0769f35c580a8f606c/onnx/english_2026-04/mimi_decoder_int8.onnx"; }
    { path = "mimi_encoder.onnx"; sha256 = "853e2ca623b8782d94c3745ec6133bfdff7ce33d9b11128bd29ea03f28d76e3d"; url = "https://huggingface.co/KevinAHM/pocket-tts-onnx/resolve/58a6d00cf13d239b6748cb0769f35c580a8f606c/onnx/english_2026-04/mimi_encoder.onnx"; }
    { path = "text_conditioner.onnx"; sha256 = "4ecee995fb69f85c7a7493d11f7b5ee15d9950facc7ab3f5c9c49ef1e03847bb"; url = "https://huggingface.co/KevinAHM/pocket-tts-onnx/resolve/58a6d00cf13d239b6748cb0769f35c580a8f606c/onnx/english_2026-04/text_conditioner.onnx"; }
    { path = "LICENSE"; sha256 = "fe7b4ce83b8381cc5b216bbb4af73c570688d1b819c73bbaed8ca401f4677cd6"; url = "https://huggingface.co/KevinAHM/pocket-tts-onnx/resolve/58a6d00cf13d239b6748cb0769f35c580a8f606c/onnx/LICENSE"; }
    { path = "voices/anna.wav"; sha256 = "0a6de25cf12bf1540beb85979f306a92be81fecc051c547c5395e7e5237a3856"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p228_023_enhanced.wav"; }
    { path = "voices/vera.wav"; sha256 = "309cf91a895830f15842b398f69a4962cb1f7e0bfab10e25dd27838e826c204b"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p229_023_enhanced.wav"; }
    { path = "voices/fantine.wav"; sha256 = "5f07d4e2a3f20a15572aae885156b43ef3fc12ef3812996fd135680d9956448b"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p244_023_enhanced.wav"; }
    { path = "voices/charles.wav"; sha256 = "6b681a429198f16e378d53bccb08d06939da7b00144a7696111d4f8f76be7756"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p254_023_enhanced.wav"; }
    { path = "voices/paul.wav"; sha256 = "7aba504fe0b3b16478b69eb27ce6007e3cb42b0c1915b5f1c6a6024ae37d679b"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p259_023_enhanced.wav"; }
    { path = "voices/eponine.wav"; sha256 = "a13c27fb47627b05223691a0ef2974358a18c886e6c2f9d2762ff1d02c20926b"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p262_023_enhanced.wav"; }
    { path = "voices/azelma.wav"; sha256 = "60e3d26cdf2efdec5df712152c839928f4d5522821e6554ae11fd96c57ab1026"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p303_023_enhanced.wav"; }
    { path = "voices/george.wav"; sha256 = "29a41f93bf5236e5b21501091d7774c255d5f3d4e62fa4f9fdf0a92a793c84ae"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p315_023_enhanced.wav"; }
    { path = "voices/mary.wav"; sha256 = "a35b0468382218e9f37a9a7494d1e4b74deaf18d7ced22265b4e325bb55c183f"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p333_023_enhanced.wav"; }
    { path = "voices/jane.wav"; sha256 = "2f12e7f155eb3118f55425394f1b049e5b1b67bdc9b3932c8ba4521420aeb84a"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p339_023_enhanced.wav"; }
    { path = "voices/michael.wav"; sha256 = "b6743e9195e5e3fd34fe9d1633ae93f7ffab787b249e45f6467d7d6f7a6ee6ad"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p360_023_enhanced.wav"; }
    { path = "voices/eve.wav"; sha256 = "396e7cbd066b0f3fb6d67fa26e7904076958239d736d4390f15b5fe88feb14cd"; url = "https://huggingface.co/kyutai/tts-voices/resolve/323332d33f997de8394f24a193e1a76df720e01a/vctk/p361_023_enhanced.wav"; }
  ];
  pocketModel = runCommand "berd-pocket-model" { } (
    ''
      mkdir -p $out/voices
    ''
    + lib.concatMapStrings (f: ''
      cp ${fetchurl { inherit (f) url sha256; }} $out/${f.path}
    '') pocketFiles
  );
in
berd.overrideAttrs (old: {
  pname = "berd-voice-test";

  preBuild = "";
  buildPhase = ''
    runHook preBuild
    (
      cd src-tauri
      cargo build --release --offline --frozen -j $NIX_BUILD_CORES \
        --target ${rustTarget} -p berd-voice --features shared --bin berd-voice
    )
    runHook postBuild
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    export HOME=$(mktemp -d)
    mkdir -p $out
    failed=0
    step() {
      echo "=== $1"
      shift
      if "$@"; then echo "=== ok"; else echo "=== FAILED ($?)"; failed=1; fi
    }

    step "berd-voice unit tests" \
      bash -c "cd src-tauri && cargo test --release --offline --frozen -j $NIX_BUILD_CORES \
        --target ${rustTarget} -p berd-voice --features shared --no-fail-fast"

    export BERD_PARAKEET_TEST_MODEL_DIR=${parakeetModel}
    step "berd-voice parakeet tests (ignored upstream without a model)" \
      bash -c "cd src-tauri && cargo test --release --offline --frozen -j $NIX_BUILD_CORES \
        --target ${rustTarget} -p berd-voice --features shared --no-fail-fast -- --ignored parakeet"

    bin=src-tauri/target/${rustTarget}/release/berd-voice
    step "ldd" bash -c "ldd $bin | tee $out/ldd.txt"
    step "STT benchmark (Parakeet, LibriSpeech fixtures)" \
      bash -c "$bin benchmark stt --stt-backend parakeet --stt-model-dir ${parakeetModel} \
        --runs 1 --mode cold | tee $out/stt.json"
    step "TTS synthesize (Pocket)" \
      bash -c "$bin synthesize --tts-backend pocket --model-dir ${pocketModel} --voice george \
        --rate 1.0 --text 'Hello from Berd on NixOS.' --output $out/hello.wav | tee $out/tts.json"
    step "TTS benchmark (Pocket)" \
      bash -c "$bin benchmark tts --tts-backend pocket --model-dir ${pocketModel} --voice george \
        --prompt-manifest english-short-v1 --mode warm | tee $out/tts-benchmark.json"

    [ "$failed" = 0 ]
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 src-tauri/target/${rustTarget}/release/berd-voice $out/bin/berd-voice
    runHook postInstall
  '';
  postInstall = "";
  postFixup = "";
  passthru = { };
  meta = old.meta // {
    mainProgram = "berd-voice";
  };
})
