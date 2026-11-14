#!/usr/bin/env bash
# Runs the GUT test suite headlessly. Set GODOT to your Godot 4.1.3 binary if it isn't on PATH.
set -euo pipefail

GODOT="${GODOT:-godot}"
cd "$(dirname "$0")"

tools/install_gut.sh

# Import the project so class_name scripts (including GUT's own) are registered.
# Godot 4.1 has no --import flag, and "--editor --quit" exits before the first
# filesystem scan finishes, so let the editor run for a while and check the cache.
CLASS_CACHE=".godot/global_script_class_cache.cfg"
for attempt in 1 2 3; do
	echo "Importing project (attempt $attempt)..."
	timeout 180 "$GODOT" --headless --editor --quit-after 2000 || true
	if [ -f "$CLASS_CACHE" ] && grep -q "GutUtils" "$CLASS_CACHE"; then
		echo "Project imported."
		break
	fi
	if [ "$attempt" -eq 3 ]; then
		echo "ERROR: project import did not register GUT classes in $CLASS_CACHE" >&2
		exit 1
	fi
done

"$GODOT" --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit
