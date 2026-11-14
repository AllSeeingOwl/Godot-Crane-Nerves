class_name BaseLevel
extends Node2D

## Common base level class for Cranial Nerve examination levels.
## Manages level lifecycle, GameState stress binding, common UI elements, and win/lose transitions.

@export var level_id: int = 1
@export var level_title: String = "Base Level"

## Fixed play-area size, used instead of the real viewport when non-zero (tests set this).
var viewport_size_override: Vector2 = Vector2.ZERO

## Short-lived patient expression (wince, grin...) layered over a level's base face.
var _reaction: Dictionary = {}
var _reaction_until_msec: int = 0

@onready var info_label: Label = $UI/InfoLabel if has_node("UI/InfoLabel") else null
@onready var controls_label: Label = $UI/ControlsLabel if has_node("UI/ControlsLabel") else null
@onready var stress_bar: ProgressBar = $UI/StressBar if has_node("UI/StressBar") else null


func _ready() -> void:
	GameState.current_level_id = level_id
	# Every level starts clean, including a retry after a game over.
	GameState.is_game_over = false
	GameState.reset_stress()
	if not GameState.stress_changed.is_connected(_on_stress_changed):
		GameState.stress_changed.connect(_on_stress_changed)
	# Restart / Menu buttons, Esc pause menu, and the win/lose screens.
	add_child(LevelOverlay.new())
	_update_ui()


func _exit_tree() -> void:
	if GameState.stress_changed.is_connected(_on_stress_changed):
		GameState.stress_changed.disconnect(_on_stress_changed)


## Size of the area the level is laid out in.
func get_play_area_size() -> Vector2:
	if viewport_size_override != Vector2.ZERO:
		return viewport_size_override
	var size := get_viewport_rect().size if is_inside_tree() else Vector2.ZERO
	return size if size != Vector2.ZERO else Vector2(1152, 648)


## Draws the shared exam-room backdrop. Call first in a level's _draw().
func draw_backdrop() -> void:
	PatientKit.draw_room(self, get_play_area_size())


## Draws the HUD backing bands. Call last in a level's _draw() (the UI layer sits above it).
func draw_hud_bands(top_h: float = 168.0, bottom_h: float = 0.0) -> void:
	PatientKit.draw_hud_bands(self, get_play_area_size(), top_h, bottom_h)


## Makes the patient pull `face` (PatientKit face keys) for `seconds`.
func react(face: Dictionary, seconds: float = 0.5) -> void:
	_reaction = face
	_reaction_until_msec = Time.get_ticks_msec() + int(seconds * 1000.0)


## The face to draw: `base` with any active reaction and the current stress applied.
func patient_face(base: Dictionary = {}) -> Dictionary:
	var face := base.duplicate()
	if not _reaction.is_empty() and Time.get_ticks_msec() < _reaction_until_msec:
		face.merge(_reaction, true)
	face["stress"] = GameState.stress
	return face


func _on_stress_changed(new_stress: float, _delta: float) -> void:
	if stress_bar:
		stress_bar.value = new_stress


func _update_ui() -> void:
	pass


func win_level() -> void:
	GameState.win_level()


func lose_level(reason: String = "Patient stress overloaded") -> void:
	GameState.game_over.emit(reason)
