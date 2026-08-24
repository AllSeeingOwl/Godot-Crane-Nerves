# ADR 0001: Choice of Game Engine (Migration to Godot)

## Status
Accepted

## Context
The original prototype of "Cranial Nerve Crisis" was built using React, TypeScript, and React Three Fiber (R3F). The core mechanic revolves around managing a "stress" value that updates 60 times a second, alongside heavy physics-based interactions in a 3D environment.

In the React ecosystem, state changes trigger component re-renders. We encountered significant performance bottlenecks (documented as "BOLT OPTIMIZATION" in the legacy code). Specifically, updating the stress state at 60fps forced constant re-creations of callbacks and teardowns of `requestAnimationFrame` loops. While memoization (`useMemo`, `useCallback`) and refs (`useRef`) mitigated this somewhat, React is fundamentally not designed as a real-time game loop engine.

Furthermore, building complex, comedy-driven physics interactions (similar to *Surgeon Simulator* or *QWOP*) using R3F and standard web physics libraries proved cumbersome and hard to tune compared to a dedicated game engine environment.

## Decision
We decided to migrate the entire project from a React/Web tech stack to **Godot Engine 4 (3D, Forward+)**.

## Rationale
1. **Native Game Loop:** Godot separates visual rendering (`_process`) from physics calculations (`_physics_process`). Updating variables like "stress" every frame has negligible performance overhead compared to React's Virtual DOM diffing.
2. **Robust 3D Physics:** Godot 4 provides a mature, built-in physics engine with nodes like `CharacterBody3D`, `RigidBody3D`, and various joints (Hinge, Slider, Generic6DOF). This makes implementing the "clunky, deliberate" controls much more straightforward.
3. **Editor Workflow:** Godot's visual editor allows for rapid iteration of level design, collision boundaries, and UI placement, which previously had to be done mostly through code in React.
4. **Export Capabilities:** Godot easily exports to Windows, macOS, Linux, and the Web (HTML5), satisfying our cross-platform requirements while providing better native performance than a browser-bound React app.

## Consequences
- **Positive:** Significant performance increase, easier physics tuning, better developer experience for level design.
- **Negative:** The team must learn GDScript (or C#) and adapt to Godot's Node/Scene architecture. The existing React logic must be manually translated into Godot scripts (hence the retention of the original Markdown files as reference).
