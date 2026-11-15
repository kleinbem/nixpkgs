#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix
# Reads the latest release from GitHub and takes the sha256 digest GitHub publishes
# for the source snapshot, so nothing gets downloaded.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

api() {
  curl --fail --silent --show-error ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    "https://api.github.com/repos/zen-browser/desktop/$1"
}

release=$(api releases/latest)
version=$(jq -er .tag_name <<< "$release")

if [[ $version == "$(jq -er .version sources.json)" ]]; then
  echo "zen-browser-unwrapped is already at $version"
  exit 0
fi

digest=$(jq -er '.assets[] | select(.name == "zen.source.tar.zst") | .digest // empty' <<< "$release") || {
  echo "error: release $version has no zen.source.tar.zst with a digest" >&2
  exit 1
}
[[ $digest == sha256:* ]] || {
  echo "error: unexpected digest '$digest'" >&2
  exit 1
}
hash=$(nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri "${digest#sha256:}")

# The Firefox version the release is based on.
firefoxVersion=$(api "contents/surfer.json?ref=$version" | jq -er .content | base64 -d | jq -er .version.version)

jq -n --arg version "$version" --arg hash "$hash" --arg firefoxVersion "$firefoxVersion" \
  '{firefoxVersion: $firefoxVersion, hash: $hash, version: $version}' > sources.json
