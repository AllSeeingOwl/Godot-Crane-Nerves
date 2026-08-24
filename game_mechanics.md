# Cranial Nerve Crisis: Game Mechanics

This document outlines the core foundational mechanics implemented for the Godot migration of Cranial Nerve Crisis.

## 1. Player Movement

The player character in this foundational setup uses a standard `CharacterBody3D` controller.
- **Input:** Standard movement is mapped to WASD/Arrow keys (`ui_left`, `ui_right`, `ui_up`, `ui_down`) which control translation along the X and Z axes. Spacebar (`ui_accept`) handles jumping.
- **Physics:** Gravity is applied when the player is not on the floor, syncing with Godot's project settings default 3D gravity. `move_and_slide()` handles moving the kinematic body through the 3D space.
- **Script:** The movement logic is defined in `scripts/player.gd`.
- **Note on Design:** The final game design for Cranial Nerve Crisis calls for deliberately convoluted controls (e.g., QWOP style limb control). The current basic character movement serves as a standard testbed for interacting with the 3D space, physics objects, and level layouts before implementing the complex rig controls described in the `00_Game_Design_Document.md`.

## 2. Collision Detection

Collision is handled through Godot's built-in 3D physics engine.
- **Player:** The `CharacterBody3D` is equipped with a `CapsuleShape3D` to approximate a human figure.
- **Environment:** Basic geometric primitives (like `CSGBox3D`) form the floor and obstacles. These have `use_collision = true` enabled, meaning they automatically generate static collision shapes that interact with the player.
- **Interactions:** The `move_and_slide()` method internally resolves collisions against the static environment, allowing the player to slide along walls and stand on floors.

## 3. Camera

- **Follow Camera:** A basic `Camera3D` is parented to the `CharacterBody3D` player node. It is offset to trail behind and above the player, providing a third-person perspective. As the player moves, the camera translates perfectly in sync.

## 4. Game-Specific Rules (Future Implementation Notes)

As per `00_Game_Design_Document.md`, the foundational mechanics will need to be expanded into the following rules:
- **Patient Stress Meter:** Interactions with the environment and specific patient actions will need to broadcast signals (e.g., `stress_increased(amount)`) to a global state manager (as detailed in `01_GameEngine_State.md`) which tracks failure states.
- **Character Physics Rig:** The standard `CharacterBody3D` will be replaced or augmented with a complex ragdoll or physics-driven rig (e.g., using `PhysicalBone3D` or distinct `RigidBody3D` segments connected via `Joint3D` nodes) to achieve the "frustration comedy" physics.
- **Input Handling Refactor:** Standard `ui_*` actions will be replaced by direct limb-mapping keys (Q, W, O, P) or laggy mouse inputs depending on the active level.

## 5. Playability and Testing

- **Testing in Editor:** Opening `scenes/Main.tscn` and running the scene (F6) allows the developer to test gravity, jump height, movement speed, and collision bounds in the 3D space.
