# Debugging and Profiling

This document outlines common issues, debugging techniques, and profiling tools for Godot-Crane-Nerves in Godot 4.

## Godot 4 Debugging Tools

### The Debugger Panel
Located at the bottom of the Godot Editor, the Debugger panel is your primary tool.
- **Errors Tab:** Watch this closely for GDScript runtime errors (e.g., null instance access, invalid casts).
- **Stack Trace:** Click on an error to see the call stack and jump directly to the offending line of code.

### Remote Scene Tree
While the game is running, you can click the **Remote** tab in the Scene dock (top left).
- This allows you to inspect the *live* state of the game, rather than the static scene file.
- You can view dynamically spawned nodes, check current property values (like `stress`), and even modify variables on the fly to test reactions.

### Breakpoints
- Click in the gutter (left of the line numbers) in the Script editor to set a breakpoint (a red dot).
- When the code hits that line, the game will pause, allowing you to step through the code line by line and inspect variable values.

## Common Issues & Solutions

### 1. "Parse Error: Expected '[ext_resource]'" or Scene Corruption
- **Cause:** Godot 4 `.tscn` files require the `[gd_scene ...]` tag to be strictly placed on the first line.
- **Solution:** Open the `.tscn` file in a text editor (not Godot) and ensure `[gd_scene ...]` is line 1, before any `[ext_resource ...]` tags.

### 2. Null Reference Errors (`get_node()` returning null)
- **Cause:** Trying to access a node that hasn't been added to the tree yet, or the node path has changed.
- **Solution:**
  - Use `%NodeName` (Scene Unique Nodes) to avoid brittle absolute paths.
  - Use `@onready var my_node = $Path/To/Node` to ensure the node is fetched after the scene is ready.
  - Double-check spelling and casing (Godot is case-sensitive).

### 3. Physics Jitter or Unpredictable Explosions
- **Cause:** RigidBody3Ds overlapping, incorrect collision layers/masks, or applying forces in `_process` instead of `_physics_process`.
- **Solution:**
  - **Always** apply physics forces and modify physics state inside `_physics_process(delta)`.
  - Check collision shapes in the editor (Debug -> Visible Collision Shapes).
  - Ensure collision layers and masks are set up correctly so objects don't collide with things they shouldn't.

### 4. CI/CD Export Failures (Headless)
- **Cause:** Missing export templates or `export_presets.cfg` issues.
- **Solution:**
  - Verify `export_presets.cfg` is tracked in Git.
  - Ensure the CI workflow clears old templates: `rm -rf ~/.local/share/godot/export_templates/`.
  - See `CI_CD_ISSUES.md` for historical fixes.

## Profiling

If the game is dropping frames or stuttering:
1. Open the **Debugger** panel while the game is running.
2. Go to the **Profiler** tab and click **Start**.
3. Play the game for a few seconds, then click **Stop**.
4. Analyze the graph. Look for spikes in `Physics Time` or `Script Time`.
   - High Script Time: Optimize complex calculations (e.g., using tables from `07_Math_Utils.md`).
   - High Physics Time: Reduce the number of active physics bodies or simplify collision shapes (use primitives like Box/Sphere instead of Convex Polygons where possible).
