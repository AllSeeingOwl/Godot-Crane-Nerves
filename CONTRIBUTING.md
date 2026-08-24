# Contributing to Cranial Nerve Crisis

Thank you for your interest in contributing to the Godot-Crane-Nerves repository! To maintain code quality and ensure a smooth development process, we follow a professional Git workflow.

## Git Workflow

We use a Git flow model tailored for CI/CD integration and reliable releases.

### Branches

*   **`main` (Production):** This is the default branch and represents the stable, production-ready state of the game. You should **never** commit directly to `main`.
*   **`develop` (Active Development):** This is the main development branch. All feature branches, bug fixes, and other work should be branched off from `develop` and merged back into it.

### Feature Branches

When you start working on an issue, feature, or bug fix:

1.  Always create a new branch from `develop`:
    ```bash
    git checkout develop
    git pull origin develop
    git checkout -b feature/your-feature-name
    ```
2.  Make your changes, following the project guidelines and reading the relevant Markdown design files.
3.  Commit your changes with clear, descriptive commit messages.

### Submitting Changes (Pull Requests)

1.  Push your branch to the remote repository:
    ```bash
    git push origin feature/your-feature-name
    ```
2.  Open a Pull Request (PR) on GitHub.
    *   **Base branch:** `develop` (for most work) or `main` (if preparing a release from `develop`).
    *   **Compare branch:** `feature/your-feature-name`
3.  **Requirements for Merging:**
    *   **Code Review:** At least one approved code review from a repository maintainer is required before a PR can be merged into `main`.
    *   **Status Checks (CI/CD):** Our automated GitHub Actions workflows (compilation, testing, and exports for Windows, macOS, Linux, and Web) must pass successfully before the PR can be merged.
4.  **After Merging:**
    *   Head branches (e.g., `feature/your-feature-name`) are configured to be automatically deleted after the PR is successfully merged.

## Reporting Issues

If you find a bug or have a feature request, please open an issue on GitHub. Make sure to describe the problem or idea clearly, including steps to reproduce bugs and expected behavior.

## Working with Godot

*   **Version:** We are currently using Godot 4.x (specifically, Godot 4.1.3 is expected by our CI/CD pipelines).
*   **Best Practices:** Follow GDScript conventions, keep your scenes modular, and avoid hardcoding values. Refer to the markdown files (e.g., `00_Game_Design_Document.md`) as the ultimate source of truth for mechanics and math logic.
