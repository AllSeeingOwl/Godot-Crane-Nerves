#!/bin/bash

# Ensure gh CLI is installed and authenticated
if ! command -v gh &> /dev/null
then
    echo "GitHub CLI (gh) is not installed. Please install it to run this script."
    exit 1
fi

if ! gh auth status &> /dev/null
then
    echo "You must be authenticated with GitHub CLI. Please run 'gh auth login' first."
    exit 1
fi

# Configuration
PROJECT_NAME="Godot-Crane-Nerves Development"
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

echo "Setting up GitHub Projects V2 Board '$PROJECT_NAME' for repository $REPO..."

# 1. Create the project
# Note: gh CLI project creation for repos currently links to the user/org.
OWNER=$(echo $REPO | cut -d'/' -f1)
echo "Creating project..."
PROJECT_NUMBER=$(gh project create --owner "$OWNER" --title "$PROJECT_NAME" --format json -q .number)

if [ -z "$PROJECT_NUMBER" ]; then
    echo "Failed to create project."
    exit 1
fi

echo "Project created successfully! Number: $PROJECT_NUMBER"

# 2. Add MVP Issues
echo "Creating MVP issues..."

ISSUE1=$(gh issue create --repo "$REPO" --title "Setup Godot project and basic project structure" --body "Initialize the Godot 4 project and establish directory structure." --label "enhancement")
ISSUE2=$(gh issue create --repo "$REPO" --title "Implement basic 3D environment ('Sterile Doctor's Office')" --body "Create the basic 3D room using layout coordinates from documentation." --label "enhancement")
ISSUE3=$(gh issue create --repo "$REPO" --title "Create the base 'Skinny Guy' physics model and ragdoll mechanics" --body "Implement the first physics character model." --label "physics")
ISSUE4=$(gh issue create --repo "$REPO" --title "Implement Global Game State (Stress Meter, Level Transitions)" --body "Create the overarching state manager for the game loop." --label "enhancement")
ISSUE5=$(gh issue create --repo "$REPO" --title "Develop Level 1: Olfactory (Smell) with QWER/AD controls" --body "Implement the first level mechanics according to documentation." --label "level-design")
ISSUE6=$(gh issue create --repo "$REPO" --title "Basic CI/CD pipeline setup for automated builds" --body "Ensure GitHub actions export the game properly." --label "enhancement")

echo "Created issues:"
echo "- $ISSUE1"
echo "- $ISSUE2"
echo "- $ISSUE3"
echo "- $ISSUE4"
echo "- $ISSUE5"
echo "- $ISSUE6"

# 3. Add issues to project
echo "Adding issues to project..."
gh project item-add $PROJECT_NUMBER --owner "$OWNER" --url $ISSUE1
gh project item-add $PROJECT_NUMBER --owner "$OWNER" --url $ISSUE2
gh project item-add $PROJECT_NUMBER --owner "$OWNER" --url $ISSUE3
gh project item-add $PROJECT_NUMBER --owner "$OWNER" --url $ISSUE4
gh project item-add $PROJECT_NUMBER --owner "$OWNER" --url $ISSUE5
gh project item-add $PROJECT_NUMBER --owner "$OWNER" --url $ISSUE6

# Note: Configuring custom columns (Backlog, In Progress, etc.) and moving items between them
# programmatically is complex via the current gh CLI and often requires GraphQL mutations.
# The created project will have default 'Todo', 'In Progress', and 'Done' statuses.
# Users are advised to customize the views in the GitHub UI.

echo "Setup complete! Please visit your GitHub repository to view the new Project and Issues."
echo "You may need to manually adjust the status columns (Backlog, In Progress, In Review, Done) in the Project settings."
