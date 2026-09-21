class_name Level5FacialNerve
extends BaseLevel

## Level 5: Facial Nerve Exam (Facial Expression Matching)
## Mechanics:
## 1. Match requested facial expressions by toggling 10 facial muscle groups (keys 1-0).
## 2. Submit the expression (Space / Enter or Submit Button) to test match.
## 3. Correct match advances progression; incorrect match adds +15 stress.
## 4. Win condition: all target expressions matched. Lose condition: stress >= 100.

const MUSCLE_NAMES: Array[String] = [
	"Forehead",
	"Left Eye",
	"Right Eye",
	"Nose",
	"Left Cheek",
	"Right Cheek",
	"Left Mouth Corner",
	"Right Mouth Corner",
	"Lips",
	"Jaw"
]

const TARGET_EXPRESSIONS: Array[Dictionary] = [
	{
		"name": "Smile",
		"required": [6, 7],
		"forbidden": [],
		"description": "Raise both corners of the mouth (Keys 7 & 8)"
	},
	{
		"name": "Frown",
		"required": [0, 9],
		"forbidden": [],
		"description": "Furrow brow and flex jaw (Keys 1 & 0)"
	},
	{
		"name": "Surprise",
		"required": [0, 8],
		"forbidden": [1, 2],
		"description": "Raise forehead and purse lips with eyes open (Keys 1 & 9)"
	},
	{
		"name": "Left Wink",
		"required": [1],
		"forbidden": [2],
		"description": "Close left eye with right eye open (Key 2)"
	},
	{
		"name": "Pout",
		"required": [3, 8],
		"forbidden": [],
		"description": "Wrinkle nose and purse lips (Keys 4 & 9)"
	}
]

const WRONG_EXPRESSION_STRESS: float = 15.0
const AMBIENT_STRESS_CHANCE: float = 0.02
const AMBIENT_STRESS_AMOUNT: float = 0.5

var muscle_states: Array[bool] = [
	false, false, false, false, false,
	false, false, false, false, false
]
var current_expression_index: int = 0
var feedback_text: String = ""
var progress: float = 0.0

@onready var feedback_label: Label = $UI/FeedbackLabel if has_node("UI/FeedbackLabel") else null
@onready var target_label: Label = $UI/TargetLabel if has_node("UI/TargetLabel") else null
@onready var progress_bar: ProgressBar = (
	$UI/ProgressBox/ProgressBar if has_node("UI/ProgressBox/ProgressBar") else null
)
@onready var muscle_container: Control = (
	$MuscleContainer if has_node("MuscleContainer") else null
)
@onready var submit_button: Button = $UI/SubmitButton if has_node("UI/SubmitButton") else null


func _ready() -> void:
	level_id = 5
	level_title = "Level 5: Facial Nerve"
	super._ready()

	if submit_button:
		submit_button.pressed.connect(submit_expression)

	_reset_muscle_states()
	_setup_muscle_visuals()
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var key_event := event as InputEventKey
	var key_code := key_event.keycode

	if key_code >= KEY_1 and key_code <= KEY_9:
		var index := key_code - KEY_1
		toggle_muscle(index)
	elif key_code == KEY_0:
		toggle_muscle(9)
	elif key_code == KEY_SPACE or key_code == KEY_ENTER or key_code == KEY_KP_ENTER:
		submit_expression()


func _process(_delta: float) -> void:
	if randf() < AMBIENT_STRESS_CHANCE:
		GameState.add_stress(AMBIENT_STRESS_AMOUNT)


func toggle_muscle(index: int) -> void:
	if index < 0 or index >= muscle_states.size():
		return
	muscle_states[index] = not muscle_states[index]
	_update_muscle_visuals()
	_update_ui()


func submit_expression() -> void:
	if current_expression_index >= TARGET_EXPRESSIONS.size():
		return

	var target: Dictionary = TARGET_EXPRESSIONS[current_expression_index]
	var is_correct := _evaluate_expression(target)

	if is_correct:
		feedback_text = "Correct! %s matched!" % target["name"]
		current_expression_index += 1
		progress = (
			float(current_expression_index) / float(TARGET_EXPRESSIONS.size()) * 100.0
		)
		_reset_muscle_states()
		_update_muscle_visuals()

		if current_expression_index >= TARGET_EXPRESSIONS.size():
			win_level()
	else:
		feedback_text = "Incorrect expression! Try again."
		GameState.add_stress(WRONG_EXPRESSION_STRESS)

	_update_ui()


func _evaluate_expression(target: Dictionary) -> bool:
	var required_indices: Array = target.get("required", [])
	var forbidden_indices: Array = target.get("forbidden", [])

	for req in required_indices:
		if not muscle_states[req]:
			return false

	for forb in forbidden_indices:
		if muscle_states[forb]:
			return false

	return true


func _reset_muscle_states() -> void:
	for i in range(muscle_states.size()):
		muscle_states[i] = false


func _setup_muscle_visuals() -> void:
	if not muscle_container:
		return

	for child in muscle_container.get_children():
		child.queue_free()

	for i in range(MUSCLE_NAMES.size()):
		var key_num := (i + 1) % 10
		var btn := Button.new()
		btn.name = "Muscle_%d" % i
		btn.text = "[%d] %s" % [key_num, MUSCLE_NAMES[i]]
		btn.pressed.connect(func(): toggle_muscle(i))
		muscle_container.add_child(btn)

	_update_muscle_visuals()


func _update_muscle_visuals() -> void:
	if not muscle_container:
		return

	var children := muscle_container.get_children()
	for i in range(children.size()):
		if i >= muscle_states.size():
			break
		var btn := children[i] as Button
		if btn:
			if muscle_states[i]:
				btn.modulate = Color(0.4, 1.0, 0.4)
			else:
				btn.modulate = Color(1.0, 1.0, 1.0)


func _update_ui() -> void:
	if info_label:
		info_label.text = "Level 5: Facial Nerve\nExpressions Matched: %d / %d" % [
			current_expression_index,
			TARGET_EXPRESSIONS.size()
		]

	if target_label:
		if current_expression_index < TARGET_EXPRESSIONS.size():
			var expr: Dictionary = TARGET_EXPRESSIONS[current_expression_index]
			target_label.text = "Requested: %s (%s)" % [expr["name"], expr["description"]]
		else:
			target_label.text = "All expressions matched!"

	if feedback_label:
		feedback_label.text = feedback_text

	if progress_bar:
		progress_bar.value = progress
