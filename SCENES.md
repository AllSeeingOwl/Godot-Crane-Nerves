# Scene Organization

This document details the major scene files within the Cranial Nerve Crisis Godot project, providing their file path, purpose, node hierarchy, and connections to other scenes.

## Directory Structure
- `scenes/player/`: Player character and player-related components.
- `scenes/enemies/`: Enemy types and AI behaviors.
- `scenes/environment/`: Level layouts, obstacles, interactive objects.
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
- **Connections**: Instantiated within `Main.tscn` or directly in level scenes (`scenes/environment/*`). Often accessed by global managers.

### Base Enemy
- **File Path**: `scenes/enemies/BaseEnemy.tscn`
- **Purpose**: Reusable base scene template for enemies. Other specific enemy variants should inherit from this scene.
- **Key Nodes**: `CharacterBody3D` (root), `CollisionShape3D`, meshes, AI controllers/navigation nodes.
- **Connections**: Inherited by specific enemy scenes. Instantiated within level scenes or via enemy spawners.

### Base Projectile
- **File Path**: `scenes/environment/BaseProjectile.tscn`
- **Purpose**: Reusable base scene template for projectiles fired by players or enemies.
- **Key Nodes**: `Area3D` or `RigidBody3D` (root), `CollisionShape3D`, `MeshInstance3D` or visual representation.
- **Connections**: Instantiated dynamically by weapons or enemy attacks.

## Creating New Scenes
When creating new scenes, ensure they are placed within the appropriate subdirectory according to their primary function.
- If a scene is meant to be a template, clearly name it with the `Base` prefix (e.g., `BaseWeapon.tscn`).
- If a scene relies on specific parent node structures, document it here or within the scene script itself using clear comments.
