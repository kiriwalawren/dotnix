#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_NIX="$REPO_ROOT/default.nix"

owner="catppuccin"
repo="userstyles"

current_rev=$(grep -oP '(?<=rev \? ")[^"]+' "$DEFAULT_NIX")

echo "Fetching latest rev and hash for $owner/$repo..."
prefetch=$(nix run nixpkgs#nix-prefetch-github -- "$owner" "$repo")

rev=$(jq -r '.rev' <<<"$prefetch")
hash=$(jq -r '.hash' <<<"$prefetch")

if [ "$rev" = "$current_rev" ]; then
  echo "catppuccin-userstyles already up to date (rev $rev)"
  exit 0
fi

sed -i \
  -e "s|rev ? \"[^\"]*\"|rev ? \"$rev\"|" \
  -e "s|hash ? \"[^\"]*\"|hash ? \"$hash\"|" \
  "$DEFAULT_NIX"

echo "Updated catppuccin-userstyles: $current_rev -> $rev"
