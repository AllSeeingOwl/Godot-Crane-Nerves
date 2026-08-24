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

## Profiling Results
*(This section should be updated periodically as development progresses and specific bottlenecks are identified and resolved via the Godot Profiler).*
