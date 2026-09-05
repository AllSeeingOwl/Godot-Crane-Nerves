class_name Level2Optic
extends BaseLevel

## Level 2: Optic Nerve Exam (Snellen Chart)
## Mechanics:
## 1. Random sequence of 10 letters from CHART_LETTERS pool
## 2. Focus level drifts towards 10 (max blur). Scroll Wheel or Up/Down arrows adjust focus.
## 3. High blur level (> 4.0 and > 7.0) steadily increases stress.
## 4. User types letters. Wrong letters increase stress (+10).
## 5. Win condition: at least 9/10 correct letters. Lose condition: < 9 correct or stress >= 100.

const CHART_LETTERS = ["C", "G", "O", "Q", "D", "P", "F", "E", "B", "R"]
const DRIFT_SPEED: float = 0.5
const WRONG_LETTER_STRESS: float = 10.0
const HIGH_BLUR_STRESS_RATE: float = 3.0
const MED_BLUR_STRESS_RATE: float = 0.6

var letters_to_type: Array[String] = []
var current_index: int = 0
var correct_count: int = 0
var focus_level: float = 5.0

@onready var focus_bar: ProgressBar = (
	$UI/FocusBox/FocusBar if has_node("UI/FocusBox/FocusBar") else null
)
@onready var letters_container: HBoxContainer = (
	$UI/SnellenChart/LettersContainer if has_node("UI/SnellenChart/LettersContainer") else null
)


func _ready() -> void:
	level_id = 2
	level_title = "Level 2: Optic Nerve"
	super._ready()

	# Generate random sequence of 10 letters if empty
	if letters_to_type.is_empty():
		for i in range(10):
			letters_to_type.append(CHART_LETTERS[randi() % CHART_LETTERS.size()])

	_setup_letter_nodes()
	_update_ui()


func _setup_letter_nodes() -> void:
	if not letters_container:
		return

	for child in letters_container.get_children():
		child.queue_free()

	for i in range(letters_to_type.size()):
		var lbl = Label.new()
		lbl.text = letters_to_type[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var size_scale = maxf(1.5, 3.5 - i * 0.2)
		lbl.add_theme_font_size_override("font_size", int(16 * size_scale))
		letters_container.add_child(lbl)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_game_over or current_index >= letters_to_type.size():
		return

	# Handle Focus controls
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			focus_level = maxf(0.0, focus_level - 0.5)
			_update_ui()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			focus_level = minf(10.0, focus_level + 0.5)
			_update_ui()
			return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_UP:
			focus_level = maxf(0.0, focus_level - 0.5)
			_update_ui()
			return
		if event.keycode == KEY_DOWN:
			focus_level = minf(10.0, focus_level + 0.5)
			_update_ui()
			return

		# Handle letter typing
		if event.keycode >= KEY_A and event.keycode <= KEY_Z:
			var typed_letter = String.chr(event.unicode).to_upper()
			if typed_letter.is_empty():
				typed_letter = OS.get_keycode_string(event.keycode).to_upper()

			_type_letter(typed_letter)


func _type_letter(typed_letter: String) -> void:
	if current_index >= letters_to_type.size():
		return

	var target_letter = letters_to_type[current_index]
	if typed_letter == target_letter:
		correct_count += 1
	else:
		GameState.add_stress(WRONG_LETTER_STRESS)

	current_index += 1
	_update_ui()

	if current_index >= letters_to_type.size():
		_check_win_condition()


func _process(delta: float) -> void:
	if GameState.is_game_over or current_index >= letters_to_type.size():
		return

	# Focus drift towards 10 (max blur)
	if focus_level < 10.0:
		focus_level = minf(10.0, focus_level + DRIFT_SPEED * delta)

	# Focus stress logic
	if focus_level > 7.0:
		GameState.add_stress(HIGH_BLUR_STRESS_RATE * delta)
	elif focus_level > 4.0:
		GameState.add_stress(MED_BLUR_STRESS_RATE * delta)

	_update_ui()


func _update_ui() -> void:
	if info_label:
		info_label.text = (
			"Level 2: Optic Nerve\nCorrect: %d / 10 | Remaining: %d"
			% [correct_count, letters_to_type.size() - current_index]
		)

	if controls_label:
		controls_label.text = (
			"Controls: Type highlighted letter! | Scroll Wheel / Up & Down Arrows to adjust Focus"
		)

	if focus_bar:
		focus_bar.value = (1.0 - focus_level / 10.0) * 100.0

	if letters_container:
		var children = letters_container.get_children()
		for i in range(children.size()):
			var lbl = children[i] as Label
			if not lbl:
				continue

			if i == current_index:
				lbl.modulate = Color(1.0, 0.9, 0.2, maxf(0.2, 1.0 - focus_level * 0.08))
			elif i < current_index:
				lbl.modulate = Color(0.4, 0.4, 0.4, 0.5)
			else:
				lbl.modulate = Color(1.0, 1.0, 1.0, maxf(0.1, 1.0 - focus_level * 0.09))


func _check_win_condition() -> void:
	if correct_count >= 9:
		win_level()
	else:
		lose_level(
			"Patient only identified %d/10 letters correctly. Need at least 9." % correct_count
		)
