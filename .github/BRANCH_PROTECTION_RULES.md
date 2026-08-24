# Branch Protection Rules

To maintain the stability of the project and ensure all code meets quality standards, we enforce branch protection rules on key branches.

## Rules for `main` Branch
The `main` branch represents the production-ready state of the game.

* **Require pull request reviews before merging**: All PRs must have at least one approved code review from a repository maintainer before they can be merged.
* **Require status checks to pass before merging**: All configured automated CI/CD checks (such as compilation, testing, and multi-platform exports via GitHub Actions) must pass successfully.
* **Do not allow bypassing the above settings**: Even administrators must follow these rules.
* **Restrict who can push to matching branches**: Direct pushes to `main` are disabled. All changes must go through a pull request.

## Rules for `develop` Branch
The `develop` branch is the main integration branch for active development.

* **Require pull request reviews before merging**: Similar to `main`, at least one approved review is required.
* **Require status checks to pass before merging**: CI/CD checks must pass to ensure the `develop` branch remains stable.
* **Restrict who can push to matching branches**: Direct pushes to `develop` are discouraged to prevent accidental breakage.

## Branch Naming Enforcement
To keep the repository organized, we follow specific naming conventions for branches. Branches should start with one of the following prefixes:
* `feature/` for new features (e.g., `feature/player-movement`)
* `bugfix/` for bug fixes (e.g., `bugfix/fix-camera-jitter`)
* `refactor/` for code refactoring

## Automated Branch Deletion
* **Automatically delete head branches**: When a pull request is merged, the head branch (e.g., `feature/player-movement`) will be automatically deleted to keep the repository clean.
