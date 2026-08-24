# CI/CD Issues Documented

This file documents the failures identified in the GitHub Actions workflows and their root causes.

## 1. Missing `export_presets.cfg`
- **Issue**: Both `.github/workflows/ci.yml` and `.github/workflows/godot-ci.yml` workflows were failing during the export step. The `godot --export-release` command and the `firebelley/godot-export` action both rely on Godot export presets.
- **Root Cause**: The repository did not contain an `export_presets.cfg` file, which defines the different build configurations (`Windows Desktop`, `Linux/X11`, `macOS`, and `Web`). In addition, the file was accidentally listed in `.gitignore`, which prevented it from being committed to the codebase.
- **Resolution**: Generated a minimal `export_presets.cfg` file with the four required profiles, removed `export_presets.cfg` from `.gitignore`, and committed it to the repository.

## 2. Missing Export Templates in `godot-ci.yml`
- **Issue**: Even with `export_presets.cfg` present, the `godot-ci.yml` workflow failed to export.
- **Root Cause**: The `godot-ci.yml` workflow relies on the `chickensoft-games/setup-godot` action. By default, this action installs the Godot editor executable but does **not** download the corresponding export templates, which are required for any headless export process.
- **Resolution**: Added a bash step in `godot-ci.yml` to explicitly download the 4.1.3 export templates (`.tpz` file), unzip them, and place them in the `~/.local/share/godot/export_templates/4.1.3.stable/` directory before running the export step.

## 3. Invalid Scene File `Main.tscn`
- **Issue**: During headless editor startup or headless export, errors appeared about `Main.tscn` containing an unrecognized file type.
- **Root Cause**: The `Main.tscn` file was improperly formatted at the top, putting the `[ext_resource]` tag on line 1 before the `[gd_scene]` root tag. Godot parser requires the `[gd_scene]` tag to be the first line of the file.
- **Resolution**: Corrected `Main.tscn` by placing `[gd_scene load_steps=5 format=3 uid="uid://cbkxhj57x6yqb"]` at the top of the file.


## Post-commit Iteration 1

### Issue 4: `firebelley/godot-export` Failed Due to Missing Export Path
* **Symptom:** The CI runner outputted multiple warnings indicating "No file path set for preset [preset_name]. Skipping export!" and subsequently failed with "No valid export presets found, exiting."
* **Root Cause:** Although `export_presets.cfg` was generated and pushed to the repository in the prior fix, the variables `export_path=""` were left empty in the configuration block. The Godot export action skips exporting presets that do not define a target build location.
* **Resolution:** Re-configured `export_presets.cfg` with precise output destinations, for instance: `export_path="build/windows/Godot-Crane-Nerves.exe"`.

### Issue 5: `firebelley/godot-export` Unexpected Input Parameter
* **Symptom:** The Action generated a deprecation/warning notification reading "Unexpected input(s) 'export_preset', valid inputs are..."
* **Root Cause:** The pipeline `.github/workflows/ci.yml` previously passed an unsupported parameter (`export_preset: "Windows Desktop"`) into the action `firebelley/godot-export@v5.2.0`, since that action natively exports *all* available configurations concurrently without needing to be invoked sequentially.
* **Resolution:** Consolidated the 4 separate operating system export jobs into a unified workflow job and stripped the unused/invalid parameters.
