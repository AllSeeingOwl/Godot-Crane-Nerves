extends CanvasLayer

@onready var stress_bar = $MarginContainer/VBoxContainer/TopRow/HBoxContainer/StressProgressBar
@onready var level_label = $MarginContainer/VBoxContainer/TopRow/LevelLabel
@onready var timer_label = $MarginContainer/VBoxContainer/TopRow/TimerLabel
@onready var pause_button = $MarginContainer/VBoxContainer/TopRow/PauseButton

var time_elapsed: float = 0.0

const LEVEL_NAMES = {
	1: "Level 1: Olfactory",
	2: "Level 2: Optic",
	3: "Level 3: Oculomotor",
	4: "Level 4: Trochlear",
	5: "Level 5: Trigeminal",
	6: "Level 6: Abducens",
	7: "Level 7: Facial",
	8: "Level 8: Vestibulocochlear",
	9: "Level 9: Glossopharyngeal",
	10: "Level 10: Vagus",
	11: "Level 11: Accessory",
	12: "Level 12: Hypoglossal"
}

func _ready():
	GameState.stress_changed.connect(_on_stress_changed)
	pause_button.pressed.connect(_on_pause_pressed)

	# Initialize HUD
	stress_bar.value = GameState.stress
	_update_level_name()

func _process(delta):
	time_elapsed += delta
	var minutes = int(time_elapsed) / 60
	var seconds = int(time_elapsed) % 60
	timer_label.text = "T: %02d:%02d" % [minutes, seconds]

func _on_stress_changed(new_stress: float, _delta: float):
	stress_bar.value = new_stress

func _on_pause_pressed():
	# Simple pause logic, could expand later
	get_tree().paused = !get_tree().paused
	pause_button.text = "RESUME" if get_tree().paused else "PAUSE"

func _update_level_name():
	var level_id = GameState.current_level_id
	level_label.text = LEVEL_NAMES.get(level_id, "Unknown Level")
