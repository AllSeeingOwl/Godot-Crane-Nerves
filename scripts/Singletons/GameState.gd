## Global GameState singleton managing game state, stress, level progression, and persistence.
extends Node

# --- Signals ---
## Emitted when stress value changes.
signal stress_changed(new_stress: float, delta: float)

## Emitted when a level is completed / won.
signal level_completed(level_id: int)

## Emitted when a level is won (for backwards compatibility).
signal level_won

## Emitted when game over / level lost occurs with a descriptive failure reason.
signal game_over(reason: String)

# --- Constants ---
const MIN_STRESS: float = 0.0
const MAX_STRESS: float = 100.0

const MIN_LEVEL_ID: int = 1
const MAX_LEVEL_ID: int = 4

const SAVE_FILE_PATH: String = "user://game_state.save"

const LEVEL_LOSE_REASONS: Dictionary = {
	1: "Patient got too stressed from the smells!",
	2: "Patient got too stressed from struggling to see!",
	3: "Patient got too stressed during the eye exam!",
	4: "Patient couldn't tolerate the facial exam!",
	5: "Patient couldn't follow the facial nerve commands!",
	6: "Patient became overwhelmed by the hearing exam!",
	7: "Patient got too stressed from the gag reflex test!",
	8: "Patient got too stressed from the resistance tests!",
	9: "Patient got too stressed from the tongue examination!",
	10: "Total systemic failure! The crisis was too much."
}

# --- Public Variables ---
var stress: float = 0.0
var current_level_id: int = 1
var highest_unlocked_level: int = 1
var completed_levels: Array[int] = []
var is_game_over: bool = false


func _ready() -> void:
	pass


# --- Public Methods ---

## Adds or subtracts stress, clamping between 0.0 and 100.0.
func add_stress(amount: float) -> void:
	if is_game_over:
		return
	var old_stress: float = stress
	stress = clamp(stress + amount, MIN_STRESS, MAX_STRESS)
	var delta: float = stress - old_stress
	stress_changed.emit(stress, delta)

	if stress >= MAX_STRESS:
		lose_level()


## Explicitly sets stress to a target value.
func set_stress(value: float) -> void:
	var delta: float = value - stress
	add_stress(delta)


## Resets stress back to 0.0.
func reset_stress() -> void:
	var delta: float = -stress
	stress = 0.0
	stress_changed.emit(stress, delta)


## Sets the active level ID (1 to 4).
func set_current_level(level_id: int) -> void:
	current_level_id = clamp(level_id, MIN_LEVEL_ID, MAX_LEVEL_ID)
	if current_level_id > highest_unlocked_level:
		highest_unlocked_level = current_level_id


## Triggers level completion / win state.
func win_level() -> void:
	if is_game_over:
		return
	if not completed_levels.has(current_level_id):
		completed_levels.append(current_level_id)

	if current_level_id < MAX_LEVEL_ID:
		highest_unlocked_level = max(highest_unlocked_level, current_level_id + 1)

	level_completed.emit(current_level_id)
	level_won.emit()


## Triggers level failure / lose state with a failure reason.
func lose_level(reason: String = "") -> void:
	if is_game_over:
		return
	is_game_over = true
	var fail_reason: String = reason
	if fail_reason.is_empty():
		fail_reason = LEVEL_LOSE_REASONS.get(
			current_level_id, "Patient got too stressed!"
		)
	game_over.emit(fail_reason)


## Advances to the next level if within bounds (1 to 4). Returns true if advanced.
func next_level() -> bool:
	if current_level_id < MAX_LEVEL_ID:
		set_current_level(current_level_id + 1)
		reset_stress()
		is_game_over = false
		return true
	return false


## Resets the entire game state to initial state.
func reset_state() -> void:
	reset_stress()
	current_level_id = MIN_LEVEL_ID
	highest_unlocked_level = MIN_LEVEL_ID
	completed_levels.clear()
	is_game_over = false


## Saves the game state to persistent storage.
func save_game_state() -> void:
	var save_data: Dictionary = {
		"stress": stress,
		"current_level_id": current_level_id,
		"highest_unlocked_level": highest_unlocked_level,
		"completed_levels": completed_levels
	}
	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string: String = JSON.stringify(save_data)
		file.store_string(json_string)


## Loads the game state from persistent storage.
func load_game_state() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return false

	var file: FileAccess = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return false

	var json_string: String = file.get_as_text()
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_string)
	if error != OK:
		return false

	var save_data: Variant = json.get_data()
	if typeof(save_data) == TYPE_DICTIONARY:
		stress = save_data.get("stress", 0.0)
		current_level_id = save_data.get("current_level_id", 1)
		highest_unlocked_level = save_data.get("highest_unlocked_level", 1)
		var comp: Array = save_data.get("completed_levels", [])
		completed_levels.clear()
		for lvl in comp:
			completed_levels.append(int(lvl))
		stress_changed.emit(stress, 0.0)
		return true
	return false
