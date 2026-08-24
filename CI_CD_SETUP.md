# CI/CD Setup Guide

This document outlines the final working configuration for the CI/CD pipeline in the Godot-Crane-Nerves project.

## Overview
The repository contains two overlapping CI/CD workflows under `.github/workflows/`:
1. `ci.yml`: Uses the `firebelley/godot-export` action to automatically handle downloading the Godot engine, the export templates, and exporting the projects.
2. `godot-ci.yml`: A more manual approach using `chickensoft-games/setup-godot` where bash scripts are used for the actual compilation and export process.

Both workflows export to **Windows, macOS, Linux, and Web**.

## Requirements

To ensure these pipelines run successfully:

### 1. Version Match
The Godot Version must be `4.1.3` (Stable).
- In `ci.yml`, this is specified in the download URLs:
  - `godot_executable_download_url: https://github.com/godotengine/godot/releases/download/4.1.3-stable/Godot_v4.1.3-stable_linux.x86_64.zip`
  - `godot_export_templates_download_url: https://github.com/godotengine/godot/releases/download/4.1.3-stable/Godot_v4.1.3-stable_export_templates.tpz`
- In `godot-ci.yml`, this is specified using the `version: 4.1.3` parameter on the `chickensoft-games/setup-godot@v2` action, as well as in the manual template download script.

### 2. Export Presets Configuration
You **must** have an `export_presets.cfg` file in the root of the project, and it **must not** be ignored by `.gitignore`.
The file should at minimum define the 4 target profiles:
- `Windows Desktop`
- `Linux/X11`
- `macOS`
- `Web`
These exact names are explicitly targeted by both workflows.

### 3. Godot Export Templates
Headless exports via bash scripts require Godot Export Templates to be installed on the runner.
For `godot-ci.yml`, we manually fetch and place the `.tpz` templates into `~/.local/share/godot/export_templates/4.1.3.stable/`.

## Debugging Future Issues
- **Action Fails Immediately on Export**: Verify that `export_presets.cfg` is checked into git and contains profiles matching the exact names requested by the Matrix or `ci.yml`.
- **Missing Template Path Errors**: Verify the exact version of the Godot Editor matches the downloaded Export Templates in the CI steps. A mismatch in subversions (e.g., `stable` vs `rc1`) will cause Godot to ignore the templates.
- **Parse Errors**: Verify scene files are well-formed (usually caused by manual edits outside the Godot Editor).

### Troubleshooting Ongoing
If using `firebelley/godot-export@v5.2.0`, it natively builds *all* presets found in `export_presets.cfg` at once, meaning you should run it as a singular build step instead of a job matrix to prevent unexpected input warnings. Be sure your `export_presets.cfg` file contains valid output paths defined at `export_path="..."` or the plugin will skip building them.
