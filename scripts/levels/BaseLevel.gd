class_name BaseLevel
extends Node2D

## Common base level class for Cranial Nerve examination levels.
## Manages level lifecycle, GameState stress binding, common UI elements, and win/lose transitions.

@export var level_id: int = 1
@export var level_title: String = "Base Level"

@onready var info_label: Label = $UI/InfoLabel if has_node("UI/InfoLabel") else null
@onready var controls_label: Label = $UI/ControlsLabel if has_node("UI/ControlsLabel") else null
@onready var stress_bar: ProgressBar = $UI/StressBar if has_node("UI/StressBar") else null


func _ready() -> void:
	GameState.current_level_id = level_id
	if not GameState.stress_changed.is_connected(_on_stress_changed):
		GameState.stress_changed.connect(_on_stress_changed)
	_update_ui()


func _exit_tree() -> void:
	if GameState.stress_changed.is_connected(_on_stress_changed):
		GameState.stress_changed.disconnect(_on_stress_changed)


func _on_stress_changed(new_stress: float, _delta: float) -> void:
	if stress_bar:
		stress_bar.value = new_stress


func _update_ui() -> void:
	pass


func win_level() -> void:
	GameState.win_level()


func lose_level(reason: String = "Patient stress overloaded") -> void:
	GameState.game_over.emit(reason)
