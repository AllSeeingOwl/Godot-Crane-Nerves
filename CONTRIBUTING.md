# Contributing to Godot-Crane-Nerves

Thank you for your interest in contributing to the Godot-Crane-Nerves project! We welcome contributions to help migrate the game into a fully functional Godot game.

To maintain code quality and ensure a smooth development process, we follow a professional Git workflow and strict coding standards.

## Git Branching Strategy

We use a Git flow model tailored for CI/CD integration and reliable releases.

### Core Branches
* **`main` (Production):** This is the default branch and represents the stable, production-ready state of the game. You should **never** commit directly to `main`.
* **`develop` (Active Development):** This is the main development branch. All feature branches, bug fixes, and other work should be branched off from `develop` and merged back into it.

### Feature and Bugfix Branches
When starting work on an issue, feature, or bug fix:
1. Always create a new branch from `develop`.
2. Follow naming conventions for your branch:
   * **Feature:** `feature/your-feature-name` (e.g., `feature/player-dash-attack`)
   * **Bugfix:** `bugfix/issue-description` (e.g., `bugfix/fix-player-movement`)
   * **Refactor:** `refactor/what-is-refactored`

```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name
```

## Pull Request Process

When you're ready to submit your changes, follow this process:

1. **Commit Your Changes:** Write clear, descriptive commit messages (see Commit Message Conventions).
2. **Push Your Branch:** Push your branch to the remote repository.
   ```bash
   git push origin feature/your-feature-name
   ```
3. **Open a Pull Request (PR):**
   * Base branch: `develop` (for most work) or `main` (if preparing a release).
   * Compare branch: Your working branch.
   * Fill out the PR template completely.
4. **Review Process:**
   * At least one approved code review from a repository maintainer is required.
   * All automated GitHub Actions status checks (CI/CD) must pass before merging.
   * Address any requested changes from the reviewers.
5. **Merge:** Once approved and checks pass, your PR will be merged. Head branches are automatically deleted after the PR is merged.

## Commit Message Conventions

Commit messages must be clear and descriptive.

* Use the **imperative mood** in the subject line (e.g., "Add player jump ability" instead of "Added player jump ability" or "Adds player jump ability").
* Keep the subject line short (under 50 characters).
* Use the body to explain **what** and **why** (rather than how).
* Reference related issue numbers if applicable.

## Coding Standards

To maintain consistency across the codebase, we enforce standard formatting rules. An `.editorconfig` file is provided in the root directory.

### General Formatting
* **Indentation**: Use **tabs** for indentation (especially in GDScript).
* **Line Endings**: Always use **LF** (Unix-style) line endings for all files.
* **File Endings**: Ensure all files end with a single empty newline.
* **Trailing Whitespace**: Remove trailing whitespace at the end of lines.

### GDScript Code Style
* **snake_case** for variables, functions, and file names (e.g., `my_variable`, `do_something()`, `my_script.gd`).
* **PascalCase** for class names and node names in the scene tree (e.g., `PlayerCharacter`, `MainLevel`).
* **UPPER_SNAKE_CASE** for constants (e.g., `MAX_HEALTH`).
* **Spacing:** Use spaces around operators and after commas.
* **Comments:** Write clear, concise comments explaining complex logic. Document public functions and classes.

## Working with Godot
* **Version:** Godot 4.1.3 (expected by CI/CD pipelines).
* Keep scenes modular and avoid hardcoding values.
* Refer to the markdown files (e.g., `00_Game_Design_Document.md`) as the ultimate source of truth for mechanics and math logic.

## Reporting Issues

If you find a bug or have a feature request, open an issue on GitHub. Describe the problem clearly, including steps to reproduce bugs and expected behavior.
