#!/usr/bin/env bash
# Downloads the GUT test addon into addons/gut (it is gitignored, not committed).
# Usage: tools/install_gut.sh [version]   (default 9.1.1, the release line for Godot 4.1)
set -euo pipefail

GUT_VERSION="${1:-9.1.1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ -f "$ROOT/addons/gut/plugin.cfg" ]; then
	echo "GUT already installed at addons/gut"
	exit 0
fi

echo "Downloading GUT v${GUT_VERSION}..."
curl -fsSL -o "$TMP/gut.zip" "https://github.com/bitwes/Gut/archive/refs/tags/v${GUT_VERSION}.zip"
unzip -q "$TMP/gut.zip" -d "$TMP"
mkdir -p "$ROOT/addons"
cp -r "$TMP/Gut-${GUT_VERSION}/addons/gut" "$ROOT/addons/gut"
echo "Installed GUT v${GUT_VERSION} to addons/gut"
