{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  boost183,
  eigen,
  gmp,
  mpfr,
  onetbb,
  parallel-hashmap,
  runCommandCC,
  # deps/OpenMeshCraft of the Bambu Studio source: build overlay and C wrapper
  bambuDeps,
  maintainers,
}:

# Bambu Studio's mesh boolean backend. Upstream builds it in its deps tree,
# fetching eigen, parallel-hashmap, oneTBB and fmt at configure time; this
# applies the same overlay with the nixpkgs libraries instead.
stdenv.mkDerivation (finalAttrs: {
  pname = "bambu-studio-openmeshcraft";
  # Must match the commit pinned in deps/OpenMeshCraft/OpenMeshCraft.cmake;
  # update-openmeshcraft.sh follows it, postPatch fails when they differ.
  version = "1.0.0-unstable-2026-08-21";

  src = fetchFromGitHub {
    owner = "bambulab";
    repo = "OpenMeshCraft";
    rev = "0e8d12c3df54804393593ab5d86c05caa340cbee";
    hash = "sha256-oMh0FIJE5lXDxfIibspJCslEAUehuP8tDIqtqF3599Y=";
  };

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    boost183
    gmp
    mpfr
    onetbb
  ];

  # Same steps as the PATCH_COMMAND in OpenMeshCraft.cmake, with the empty
  # submodule placeholders filled from nixpkgs.
  postPatch = ''
    if ! grep -q 'OpenMeshCraft/archive/${finalAttrs.src.rev}\.zip' ${bambuDeps}/OpenMeshCraft.cmake; then
      echo "bambu-studio pins another OpenMeshCraft commit; update openmeshcraft.nix" >&2
      exit 1
    fi

    cp ${bambuDeps}/CMakeLists.txt.in CMakeLists.txt
    cp ${bambuDeps}/OpenMeshCraftConfig.cmake.in .
    cp -r ${bambuDeps}/wrapper bambu_wrapper
    chmod -R u+w bambu_wrapper

    sed -n '/external_CMakeLists.txt" \[=\[/,/^\]=\])/p' ${bambuDeps}/OpenMeshCraft.cmake \
      | sed '1d;$d' > external/CMakeLists.txt
    test -s external/CMakeLists.txt

    rmdir external/eigen external/parallel-hashmap
    ln -s ${eigen}/include/eigen3 external/eigen
    cp -r ${parallel-hashmap.src} external/parallel-hashmap
    chmod -R u+w external/parallel-hashmap
  '';

  cmakeFlags = [
    (lib.cmakeBool "OMC_BUILD_TEST" false)
    (lib.cmakeBool "OMC_MASTER_PROJECT" false)
    (lib.cmakeBool "OMC_BUILD_PREDICATES_GENERATOR" false)
    (lib.cmakeBool "CMAKE_POSITION_INDEPENDENT_CODE" true)
    # The overlay defaults to -mavx2 -mfma on every non-Apple platform, which
    # breaks aarch64 and older x86_64 CPUs.
    (lib.cmakeBool "OMC_CMAKE_ENABLE_SSE2" false)
    (lib.cmakeBool "OMC_CMAKE_ENABLE_AVX" false)
    (lib.cmakeBool "OMC_CMAKE_ENABLE_AVX2" false)
    (lib.cmakeBool "OMC_CMAKE_ENABLE_FMA" false)
  ];

  passthru.tests.boolean =
    runCommandCC "bambu-studio-openmeshcraft-test"
      {
        buildInputs = [
          finalAttrs.finalPackage
          gmp
          mpfr
          onetbb
        ];
      }
      ''
        $CXX -std=c++20 ${./test-openmeshcraft.cpp} -o test \
          -lOpenMeshCraftBoolean -lOpenMeshCraft -lshewchuk_predicates -ltbb -lmpfr -lgmp
        ./test | tee $out
      '';

  meta = {
    description = "Mesh boolean library used by Bambu Studio";
    homepage = "https://github.com/bambulab/OpenMeshCraft";
    license = with lib.licenses; [
      gpl3Only
      lgpl3Only
    ];
    inherit maintainers;
    platforms = lib.platforms.linux;
  };
})
