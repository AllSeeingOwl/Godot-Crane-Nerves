#!/bin/bash

# This script configures the GitHub repository settings to match the professional Git workflow.
# Requires GitHub CLI (gh) to be installed and authenticated (`gh auth login`).
# It will:
# 1. Ensure `develop` branch exists and is pushed.
# 2. Set `main` as the default branch.
# 3. Enable branch protection on `main` (requires 1 review, requires status checks).
# 4. Enable automatic deletion of head branches after PR merge.

set -e

REPO="AllSeeingOwl/Godot-Crane-Nerves"

echo "Checking GitHub CLI authentication..."
gh auth status || { echo "Please run 'gh auth login' first."; exit 1; }

echo "Ensuring 'develop' branch exists remotely..."
git branch develop 2>/dev/null || true
git push origin develop || { echo "Failed to push develop branch. Make sure you are in the repository and develop branch exists locally."; exit 1; }

echo "Setting 'main' as the default branch..."
gh api -X PATCH /repos/$REPO -f default_branch=main

echo "Configuring automatic deletion of head branches on PR merge..."
gh api -X PATCH /repos/$REPO -F delete_branch_on_merge=true

echo "Setting branch protection rules on 'main'..."
# Status checks names based on the job names in .github/workflows/ci.yml
# Need to send a PUT request to the branch protection endpoint
gh api -X PUT /repos/$REPO/branches/main/protection \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -F "required_status_checks[strict]=true" \
  -F "required_status_checks[contexts][]=Windows Export" \
  -F "required_status_checks[contexts][]=macOS Export" \
  -F "required_status_checks[contexts][]=Linux Export" \
  -F "required_status_checks[contexts][]=Web Export" \
  -F "enforce_admins=false" \
  -F "required_pull_request_reviews[required_approving_review_count]=1" \
  -F "restrictions=null"

echo "Repository configuration complete!"
