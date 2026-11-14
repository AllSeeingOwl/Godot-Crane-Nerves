# API Documentation

This document describes the primary scripts, singletons, and public methods planned or implemented for Godot-Crane-Nerves.

## Singletons (Autoloads)

### `GameState.gd`
Manages the global state of the game, including stress, current level, and scene transitions.

**Properties:**
- `current_level_id : int`: The ID of the current active level (1-12).
- `current_stress : float`: The patient's current stress level (0.0 to 100.0).
- `max_stress : float`: The threshold for failing a level (default 100.0).

**Signals:**
- `stress_changed(new_stress: float, delta: float)`: Emitted whenever the stress level changes.
- `level_started(level_id: int)`: Emitted when a new level begins.
- `game_over(reason: String)`: Emitted when stress reaches the maximum or another fail state occurs.
- `level_won()`: Emitted when the current level's objectives are met.

**Methods:**
- `add_stress(amount: float) -> void`: Increases the patient's stress. Triggers `game_over` if it exceeds `max_stress`.
- `reduce_stress(amount: float) -> void`: Decreases the patient's stress (clamps at 0).
- `load_level(level_id: int) -> void`: Transitions the scene to the specified level ID.
- `restart_level() -> void`: Reloads the current level and resets stress.

### `AudioManager.gd`
Manages background music, ambient audio, and one-shot sound effects.

**Methods:**
- `play_bgm(track_name: String) -> void`: Plays a looping background track.
- `play_sfx(sfx_name: String) -> void`: Plays a one-shot sound effect.
- `set_ambient_audio(enabled: bool) -> void`: Toggles the ambient office audio (similar to `useAmbientAudio` hook).

## Base Classes

### `BaseLevel.gd`
A base script that all level controllers should inherit from. Provides common functionality for managing level-specific states.

**Properties:**
- `level_id : int`: The ID of the level.
- `is_active : bool`: Whether the level is currently being played.

**Methods:**
- `_on_level_start() -> void`: Virtual method called when the level begins.
- `win_level() -> void`: Tells `GameState` that the level is won.
- `lose_level(reason: String) -> void`: Tells `GameState` the level is lost with a specific reason.

## HUD / UI

Each level draws its own HUD labels and stress bar (`UI` CanvasLayer in its scene).

### `LevelOverlay` (`scripts/ui/level_overlay.gd`)
Added to every level by `BaseLevel._ready()`.

- Always-visible **Restart** and **Menu** buttons (top left); **Esc** opens a pause menu (Resume / Restart / Main Menu).
- `show_passed(level_title, has_next)`: "Exam passed" screen (Next Level / Restart / Main Menu); after the last level it shows `show_complete()` instead (Play Again / Main Menu).
- `show_failed(reason)`: "Exam failed" screen with the reason (Retry / Main Menu).
- The scene tree is paused while a panel is open (`pause_tree`, turned off in tests); **Enter** presses the highlighted button.

`LevelManager` shows these screens from its `level_won` / `game_over` handlers, and provides `restart_level()` and `go_to_main_menu()`.
