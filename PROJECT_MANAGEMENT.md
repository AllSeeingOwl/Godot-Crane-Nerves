# Project Management Guidelines

Welcome to the **Cranial Nerve Crisis** development project! This document outlines how we track progress, manage tasks, and coordinate our development efforts using GitHub's built-in tools.

## 1. GitHub Issues

We use GitHub Issues as our primary source of truth for all tasks, bugs, and feature ideas.

### Creating an Issue
- Always use the appropriate Issue Template (Bug Report or Feature Request) when creating a new issue.
- **Bug Reports** must include clear reproduction steps, expected behavior, actual behavior, and environment details (OS, Godot version).
- **Feature Requests** should clearly outline the proposed solution and define acceptance criteria to clarify when the feature is considered "done."
- Assign relevant **labels** (e.g., `bug`, `enhancement`, `level-design`, `physics`, `audio`) to help categorize the issue.

### Lifecycle of an Issue
1. **Creation:** An issue is created and automatically placed in the "Backlog" of our Project Board.
2. **Triage:** Maintainers will review the issue, assign priorities, add labels, and potentially assign it to a Milestone.
3. **In Progress:** Once a developer starts working on the issue, they should assign themselves and move the issue to the "In Progress" column on the Project Board.
4. **In Review:** When a Pull Request (PR) is opened to address the issue, the issue moves to "In Review." The PR should reference the issue number (e.g., `Fixes #12`).
5. **Done:** When the PR is approved and merged into `develop` or `main`, the issue is closed and moves to the "Done" column.

## 2. GitHub Projects V2 Board

We use a GitHub Projects V2 board named **"Godot-Crane-Nerves Development"** to visualize our workflow.

The board consists of the following columns:
- **Backlog:** All newly created and unassigned issues live here. This is prioritized top-to-bottom.
- **In Progress:** Issues currently being actively worked on by a developer.
- **In Review:** Issues that have an open Pull Request awaiting review from a maintainer and passing CI/CD checks.
- **Done:** Issues that have been successfully merged and closed.

Developers should ensure their assigned issues are always in the correct column reflecting their current state.

## 3. Milestones

We use GitHub Milestones to group issues into significant releases or developmental phases, aligning with our `ROADMAP.md`.

Our major milestones include:
- **MVP (Minimum Viable Product):** Core systems, basic physics, and Level 1.
- **Alpha:** Integration of both character models, Levels 2-5, and basic audio.
- **Beta:** All remaining levels (6-9) completed, "Window of Distraction" implemented, and full audio pass.
- **Release:** Final QA, bug fixing, and CI/CD polish for public launch.

Every issue that contributes to a milestone should be assigned to that milestone. This allows us to track the percentage completion of each major phase of development.
