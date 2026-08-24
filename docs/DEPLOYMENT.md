# Deployment and Build Guide

This document outlines the steps to build, export, and deploy Godot-Crane-Nerves for various platforms.

## Overview

The project uses Godot Engine version **4.1.3**.
Automated builds are handled via GitHub Actions (CI/CD), but manual local exports are also possible.

The configured export presets (`export_presets.cfg`) are:
- `Windows Desktop`
- `macOS`
- `Linux/X11`
- `Web`

## Automated CI/CD (GitHub Actions)

The repository is configured to automatically compile, run tests, and export builds on pushes and pull requests to the `main` branch.

### How it works:
1. The workflow uses Ubuntu runners.
2. It downloads the Godot 4.1.3 headless executable and export templates.
3. It installs the templates to `~/.local/share/godot/export_templates/4.1.3.stable/`.
4. To prevent "Directory not empty" errors, the workflow runs `rm -rf ~/.local/share/godot/export_templates/` before downloading fresh templates.
5. It runs Godot in headless mode with the `--export-release` flag for each preset defined in `export_presets.cfg`.
6. Artifacts are uploaded to the GitHub Actions run.

*For detailed troubleshooting of the pipeline, see `CI_CD_ISSUES.md` and `CI_CD_SETUP.md`.*

## Manual Local Export

If you need to build the game locally for testing:

### 1. Install Export Templates
1. Open Godot.
2. Go to **Editor -> Manage Export Templates**.
3. Ensure the templates for Godot 4.1.3 are downloaded and installed.

### 2. Exporting the Project
1. Go to **Project -> Export**.
2. Select the desired platform on the left (e.g., Windows Desktop).
3. Set the **Export Path** (e.g., `build/windows/CraneNerves.exe`).
4. Click **Export Project**.
5. Do *not* check "Export with Debug" if you are building a release version for players.

### 3. Web Exports
When exporting for Web (HTML5):
- Ensure you have configured a web server to serve the exported files with the correct headers (Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy) required by Godot 4's SharedArrayBuffer.
- The entry point will be `index.html`.

## Release Process

1. Ensure the code is merged into `main` and CI/CD tests pass.
2. Draft a new Release on GitHub.
3. Tag the release appropriately (e.g., `v1.0.0`).
4. The CI/CD pipeline (if configured for release tags) or manual upload will attach the built binaries (Windows `.zip`, Linux `.tar.gz`, macOS `.app.zip`, Web `.zip`) to the release page.
