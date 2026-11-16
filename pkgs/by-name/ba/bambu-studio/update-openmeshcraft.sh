#!/usr/bin/env nix-shell
#!nix-shell -i bash -p common-updater-scripts curl gnugrep jq

# Moves openmeshcraft.nix to the OpenMeshCraft commit pinned by the current
# bambu-studio source.

set -euo pipefail

src=$(nix-build --no-out-link -A bambu-studio.src)
rev=$(grep -oP 'OpenMeshCraft/archive/\K[0-9a-f]{40}(?=\.zip)' "$src/deps/OpenMeshCraft/OpenMeshCraft.cmake")
old_rev=$(nix-instantiate --eval --raw -A bambu-studio.openmeshcraft.src.rev)

if [[ "$rev" == "$old_rev" ]]; then
  exit 0
fi

old_version=$(nix-instantiate --eval --raw -A bambu-studio.openmeshcraft.version)
date=$(curl -sSfL "https://api.github.com/repos/bambulab/OpenMeshCraft/commits/$rev" | jq -r .commit.committer.date)

update-source-version bambu-studio.openmeshcraft "${old_version%%-unstable-*}-unstable-${date:0:10}" \
  --rev="$rev" --file=pkgs/by-name/ba/bambu-studio/openmeshcraft.nix
