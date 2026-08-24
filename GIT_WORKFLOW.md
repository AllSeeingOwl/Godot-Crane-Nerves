# Git Workflow Visual Guide

This document visualizes the Git workflow used in the Godot-Crane-Nerves project. It illustrates how feature branches, bugfixes, and releases move through the `develop` and `main` branches.

## The Development Flow

```mermaid
gitGraph
    commit id: "Initial Commit"
    branch develop
    checkout develop
    commit id: "Setup project"

    %% Feature 1
    branch feature/player-movement
    checkout feature/player-movement
    commit id: "Add player script"
    commit id: "Add dash ability"
    checkout develop
    merge feature/player-movement id: "PR: Player Movement" type: REVERSE

    %% Bugfix
    branch bugfix/camera-jitter
    checkout bugfix/camera-jitter
    commit id: "Fix jitter in camera"
    checkout develop
    merge bugfix/camera-jitter id: "PR: Fix Camera" type: REVERSE

    %% Feature 2
    branch feature/level-1
    checkout feature/level-1
    commit id: "Add level geometry"
    commit id: "Add enemies"
    checkout develop
    merge feature/level-1 id: "PR: Level 1" type: REVERSE

    %% Release to Main
    checkout main
    merge develop id: "PR: Release v1.0" tag: "v1.0" type: HIGHLIGHT

    %% Further development
    checkout develop
    commit id: "Start next sprint"
```

## Step-by-Step Process

1. **Start from `develop`**:
   All new work starts by branching off the `develop` branch.
   ```bash
   git checkout develop
   git pull origin develop
   ```

2. **Create a Feature/Bugfix Branch**:
   Create a new branch for your specific task using the proper naming convention.
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Develop and Commit**:
   Make your changes, test them locally, and commit with clear messages.
   ```bash
   git add .
   git commit -m "Add new feature functionality"
   ```

4. **Push and Open a Pull Request**:
   Push your branch to GitHub and open a Pull Request targeting the `develop` branch.
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Review and Merge**:
   After the PR passes automated checks and is approved by a reviewer, it is merged into `develop`. Your feature branch can then be deleted.

6. **Release to `main`**:
   When `develop` reaches a stable milestone, a Pull Request is opened to merge `develop` into `main`. This triggers a release and represents the new production state.
