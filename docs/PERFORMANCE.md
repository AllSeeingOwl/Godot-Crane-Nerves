# Performance and Optimization

This document covers performance considerations, known bottlenecks, and optimization tips specific to Godot-Crane-Nerves.

## React to Godot Advantages

The primary reason for migrating from React (using React Three Fiber) to Godot 4 is performance and stability.
In the original React prototype (see the "BOLT OPTIMIZATION" notes in `01_GameEngine_State.md`), updating the `stress` variable 60 times a second caused severe performance degradation due to React's rendering lifecycle and constant recreation of callbacks, which forced teardowns of `requestAnimationFrame` loops.

Godot natively handles game loops (`_process` and `_physics_process`), eliminating this specific bottleneck. Updating a float value like `stress` every frame in Godot is practically free.

## Known Bottlenecks

### 1. 3D Physics Calculations
Because the game relies heavily on physics-based comedy (like *Surgeon Simulator*), complex joint setups or overlapping collision boundaries can cause the physics solver to spike in CPU usage.
- **Symptom:** Physics jitter, frame rate drops during complex interactions (e.g., Level 7 Gag Reflex).
- **Measurement:** Check "Physics Time" in the Godot Profiler.

### 2. Math Overhead
Certain levels require calculating vectors, distances, and torques rapidly.
- **Optimization:** Use the pre-calculated tables or optimized formulas provided in `07_Math_Utils.md` instead of performing expensive trig functions (`sin`, `cos`, `atan2`) excessively every frame if an approximation is sufficient.

## General Optimization Tips

1. **Use `_physics_process` correctly:** Only put code related to physics bodies (`move_and_slide()`, `apply_central_force()`, etc.) inside `_physics_process`. Put visual updates, UI updates, and timers in `_process`.
2. **Signals vs. Polling:** Do not use `_process` to constantly check if a state has changed (polling). Instead, emit a signal when the state changes and connect a function to that signal.
3. **Collision Shapes:** Always use primitive shapes (Box, Sphere, Capsule, Cylinder) for collisions whenever possible. Avoid `ConvexPolygonShape3D` or `ConcavePolygonShape3D` for dynamic rigid bodies, as they are significantly more expensive to compute.
4. **Instancing:** If a level requires spawning many objects (e.g., droplets, particles), use object pooling or Godot's built-in `MultiMeshInstance3D` or `GPUParticles3D` rather than instantiating hundreds of individual Node3Ds.
5. **Print Statements:** Remove or disable `print()` statements in production code, especially inside `_process` or `_physics_process`, as excessive console I/O will severely impact framerate.

## Profiling & Optimization Report

### Summary of Identified Bottlenecks & Implemented Fixes

1. **Ragdoll Physics & Stress Calculations (`RagdollCharacter.gd`)**
   - **Bottleneck:** Updating 14 rigid body velocities in `_calculate_and_apply_stress()` using dynamic `Dictionary` lookups (`_previous_velocities[body]`) was incurring dictionary hashing overhead on every physics frame. Additionally, `push_body_part()` performed string matching across node children when retrieving limbs.
   - **Optimization:** Replaced the dictionary with a contiguous parallel `Array[Vector3]` indexed by body part ID. Added a cached `_body_parts_by_name` lookup table to allow O(1) limb retrieval by name without iterating children or using regex matching.

2. **3D Environment Rendering (`doctors_office.tscn` & `DoctorsOffice.tscn`)**
   - **Bottleneck:** `doctors_office.tscn` contained multiple individual `OmniLight3D` nodes for each ceiling panel (`CeilingLightPanel0`, `CeilingLightPanel1`, `CeilingLightPanel2`), with overlapping light ranges (9.0 units). Overlapping omni lights increase pixel shader cost significantly in 3D Forward rendering due to multiple light passes per fragment.
   - **Optimization:** Consolidated the ceiling light sources into a single central ceiling `OmniLight3D` with appropriate coverage. Reduced light omni ranges on ambient lights across environment scenes (e.g., from 7.0/10.0 to 6.0) to minimize light overlap and draw calls.

3. **Input Handling Latency (`Level1_Olfactory.gd`)**
   - **Bottleneck:** Mouse lag calculation used `get_global_mouse_position()` inside `_process()` with framerate-dependent linear `lerp(target, LAG_SPEED * delta)`. Polling mouse position in `_process()` introduced up to 1 frame of input lag before movement processing, and standard linear lerp behaved inconsistently at fluctuating framerates.
   - **Optimization:** Captured exact cursor position in `_unhandled_input(event)` on `InputEventMouseMotion` to eliminate polling delay. Replaced linear lerp with frame-rate independent exponential decay interpolation (`1.0 - exp(-LAG_SPEED * delta)`), providing smooth, precise movement regardless of frame rate.

4. **Memory Usage for Level Transitions (`BaseLevel.gd` & `LevelManager.gd`)**
   - **Bottleneck:** Signal handlers connected to global `GameState` singleton during level execution risked leaking node references or triggering redundant handlers across scene reloads if not cleanly unhooked.
   - **Optimization:** Ensured explicit signal disconnection in `BaseLevel._exit_tree()` (`GameState.stress_changed.disconnect`) and guarded signal connections in `LevelManager.gd` against duplication.
