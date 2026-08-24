# CI/CD Dashboard

This dashboard provides an overview of the continuous integration and continuous deployment pipelines for the Cranial Nerve Crisis project.

## Workflow Status

*Note: Replace `your-username/Godot-Crane-Nerves` with your actual repository to see live status badges.*

| Workflow | Status Badge | Description | Links |
| :--- | :--- | :--- | :--- |
| **Godot CI/CD** | [![Godot CI/CD](https://github.com/your-username/Godot-Crane-Nerves/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/Godot-Crane-Nerves/actions/workflows/ci.yml) | Fast pipeline for `develop` and PRs to `main`. Focuses on fast feedback, linting, and basic export checks. | [View Runs](https://github.com/your-username/Godot-Crane-Nerves/actions/workflows/ci.yml) |
| **Godot Build and Export (Release)** | [![Godot Build and Export](https://github.com/your-username/Godot-Crane-Nerves/actions/workflows/godot-ci.yml/badge.svg)](https://github.com/your-username/Godot-Crane-Nerves/actions/workflows/godot-ci.yml) | Comprehensive pipeline on `main`. Runs tests, builds for all platforms, generates changelogs, and creates GitHub Releases. | [View Runs](https://github.com/your-username/Godot-Crane-Nerves/actions/workflows/godot-ci.yml) |
| **Nightly Build** | [![Nightly Godot Build](https://github.com/your-username/Godot-Crane-Nerves/actions/workflows/nightly-build.yml/badge.svg)](https://github.com/your-username/Godot-Crane-Nerves/actions/workflows/nightly-build.yml) | Runs daily at 02:00 UTC. Full test suite and export process to catch regressions or unstable dependencies early. | [View Runs](https://github.com/your-username/Godot-Crane-Nerves/actions/workflows/nightly-build.yml) |

---

## Performance Benchmarks

Performance metrics are now automatically generated during workflow runs and appear in the GitHub Actions **Step Summary** view.
* **Test Phase Duration:** Found under the "Build & Test" job summary.
* **Export Duration:** Found under individual export jobs (Windows, Linux, macOS, Web).

Monitor these metrics for unexpected increases in build times, which may indicate bloated assets, inefficient code compilation, or runner issues.

---

## Troubleshooting Guide

When a pipeline fails, check the GitHub Actions logs for the specific step that triggered the failure. Below are common issues and their resolutions:

### 1. `Directory not empty` error during Export Cache Cleanup
* **Symptom:** The `firebelley/godot-export` action fails when trying to place templates.
* **Resolution:** Ensure the `Clean existing templates` step (`rm -rf ~/.local/share/godot/export_templates/`) runs successfully *before* the export step.

### 2. Export Presets Missing
* **Symptom:** Build fails with `Failed to load export preset`.
* **Resolution:** Ensure `export_presets.cfg` is committed to the repository and explicitly contains the platform name expected by the matrix (e.g., "Windows Desktop", "Linux/X11", "macOS", "Web"). Do *not* add this file to `.gitignore`.

### 3. Missing Export Templates
* **Symptom:** Error stating `No export templates found`.
* **Resolution:** Godot export templates for the exact version (4.1.3.stable) must be properly cached or downloaded during the job. Check the "Install Export Templates" step logs to see if the `wget` or `unzip` commands failed due to network issues.

### 4. Headless Asset Import Failure
* **Symptom:** The `Import Assets` step fails or hangs indefinitely.
* **Resolution:** This can occur if bad resources are committed, or if scene files do not have `[gd_scene]` as their very first line. Review your most recent commits for malformed `.tscn` files or unsupported asset types.

### 5. `gdlint` / Linting Errors
* **Symptom:** The `Lint GDScript` job fails.
* **Resolution:** Review the logs for the exact line numbers that violate styling rules. Use `gdformat` locally on your GDScript files to automatically fix standard formatting issues before pushing.

### 6. GUT Unit Tests Fail
* **Symptom:** The "Verify compilation and tests" step fails and outputs GUT failure summaries.
* **Resolution:** Check the log output for which specific assertions failed. Run tests locally using `res://addons/gut/gut_cmdln.gd` to debug.

### Notifications

Pipeline failures on the `ci.yml`, `godot-ci.yml`, and `nightly-build.yml` workflows will attempt to send a Slack notification. Ensure the repository has the `SLACK_WEBHOOK` secret configured appropriately.
