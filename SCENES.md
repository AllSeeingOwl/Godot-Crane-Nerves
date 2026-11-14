# Scene Organization

This document details the major scene files within the Cranial Nerve Crisis Godot project, providing their file path, purpose, node hierarchy, and connections to other scenes.

## Directory Structure
- `scenes/player/`: Player character and player-related components.
- `scenes/levels/`: One scene per cranial nerve exam level (`LevelN_Name.tscn`).
- `scenes/environments/`: The 3D doctor's office backdrop (`doctors_office.tscn`).
- `scenes/ui/`: Menus, HUD, dialogue boxes.

## Major Scenes

### Main Scene
- **File Path**: `scenes/Main.tscn`
- **Purpose**: The core entry point for the game. Serves as the root scene managing the transition between levels and menus.
- **Key Nodes**: Contains the root node to load and instantiate subsequent scenes like the Player or Environment scenes.
- **Connections**: Acts as the parent scene for current level environment, player scene, and UI/HUD elements.

### Player Scene
- **File Path**: `scenes/player/player.tscn`
- **Purpose**: The main player character entity, handling input, physics, interactions, and camera.
- **Key Nodes**: `CharacterBody3D` (root), `CollisionShape3D`, `Camera3D` (or similar for perspective).
- **Connections**: Instantiated within `Main.tscn`.

### Level Scenes
- **File Path**: `scenes/levels/LevelN_Name.tscn` (e.g. `Level1_Olfactory.tscn`)
- **Purpose**: One 2D minigame per cranial nerve test. Root node is a `Node2D` whose script extends `BaseLevel`.
- **Connections**: Loaded by the `LevelManager` autoload via its `LEVEL_SCENES` table.

### Doctor's Office
- **File Path**: `scenes/environments/doctors_office.tscn`
- **Purpose**: The 3D sterile office backdrop, with a mouse-parallax camera (`scripts/environments/doctors_office.gd`).

## Creating New Scenes
When creating new scenes, ensure they are placed within the appropriate subdirectory according to their primary function.
- If a scene is meant to be a template, clearly name it with the `Base` prefix (e.g., `BaseWeapon.tscn`).
- If a scene relies on specific parent node structures, document it here or within the scene script itself using clear comments.
