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

### 3. Web Exports & GitHub Pages Deployment

Godot 4 Web exports rely on `SharedArrayBuffer`, which requires Cross-Origin Isolation HTTP headers:
- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`

Because GitHub Pages does not support custom HTTP response headers, our automated workflow automatically integrates [coi-serviceworker](https://github.com/gzuidhof/coi-serviceworker). This service worker intercepts network requests and sets the necessary Cross-Origin Isolation headers client-side.

#### Automated GitHub Pages Deployment Workflow

1. Whenever code is pushed to the `main` branch, the `.github/workflows/godot-ci.yml` workflow:
   - Builds the project for Web (`preset_name: "Web"`).
   - Downloads `coi-serviceworker.min.js` into the export output directory.
   - Injects `<script src="coi-serviceworker.min.js"></script>` into the HTML `<head>` tag of `index.html`.
   - Creates a `.nojekyll` file in the build output to ensure GitHub Pages does not filter out Godot export files starting with underscores.
   - Deploys the web build artifacts directly to the `gh-pages` branch via `peaceiris/actions-gh-pages`.

#### Configuring GitHub Pages in Repository Settings

To enable live web testing on GitHub Pages for your repository:

1. Go to your GitHub repository in a browser.
2. Click **Settings** in the top navigation bar.
3. In the left sidebar under **Code and automation**, click **Pages**.
4. Under **Build and deployment**:
   - Set **Source** to **Deploy from a branch**.
   - Under **Branch**, select `gh-pages` and `/ (root)`.
   - Click **Save**.
5. After the workflow completes, your game will be accessible at:
   `https://<your-username>.github.io/<repository-name>/`

## Release Process

1. Ensure the code is merged into `main` and CI/CD tests pass.
2. Draft a new Release on GitHub.
3. Tag the release appropriately (e.g., `v1.0.0`).
4. The CI/CD pipeline (if configured for release tags) or manual upload will attach the built binaries (Windows `.zip`, Linux `.tar.gz`, macOS `.app.zip`, Web `.zip`) to the release page.
