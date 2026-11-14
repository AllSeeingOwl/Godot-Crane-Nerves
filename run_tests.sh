#!/usr/bin/env bash
# Runs the GUT test suite headlessly. Set GODOT to your Godot 4.1.3 binary if it isn't on PATH.
set -euo pipefail

GODOT="${GODOT:-godot}"
cd "$(dirname "$0")"

tools/install_gut.sh

# Import the project first so class_name scripts are registered (Godot 4.1 has no --import flag).
"$GODOT" --headless --editor --quit >/dev/null 2>&1 || true

"$GODOT" --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit
