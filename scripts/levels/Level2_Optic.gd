class_name Level2Optic
extends BaseLevel

## Level 2: Optic Nerve Exam (Visual Acuity, Dual Eye Control)
## The patient reads a shaky Snellen chart, and you steer each of their eyeballs separately.
## Mechanics:
## - Left eye: W/A/S/D. Right eye: Arrow keys. (Gamepad: left / right stick.)
## - Each eye's gaze point floats around the "Patient's view" panel with momentum, and slowly
##   drifts outward (lazy eyes), so it needs constant correction.
## - Each eye sees its own copy of the chart, offset by that eye's aim error: misaligned eyes
##   give double vision; when both are on the highlighted letter the view snaps sharp.
## - Hold both eyes on the highlighted letter for READ_TIME to read it. Targets go down the
##   chart, so each is smaller than the last. Read every target to win.
## - The chart sways and jitters. Crossing the eyes too far, or rolling them off the chart,
##   adds stress. Lose condition: stress >= 100.

const LEFT: int = 0
const RIGHT: int = 1

## Panel that shows what the patient sees, and the chart inside it (screen space).
const VIEW_RECT: Rect2 = Rect2(560, 165, 540, 440)
const CHART_RECT: Rect2 = Rect2(700, 190, 260, 390)

const CHART_ROWS: Array[String] = ["E", "FP", "TOZ", "LPED", "PECFD", "EDFCZP", "FELOPZD"]
const ROW_FONT_SIZES: Array[int] = [64, 46, 36, 28, 22, 18, 15]
const ROW_SPACING: float = 52.0

const GAZE_ACCEL: float = 900.0
const GAZE_FRICTION: float = 3.0
const OUTWARD_DRIFT: float = 30.0
const READ_TIME: float = 0.8
const READ_DECAY_RATE: float = 1.5
const CROSS_EYED_DISTANCE: float = 170.0
const CROSS_EYED_STRESS_PER_SEC: float = 8.0
const OFF_CHART_STRESS_PER_SEC: float = 10.0

const SHAKE_AMPLITUDE: Vector2 = Vector2(10, 7)
const JOY_DEADZONE: float = 0.2

const FACE_CENTER: Vector2 = Vector2(300, 400)
const FACE_SCALE: float = 120.0

## Target letters, one per row from the top: [row, column] pairs.
var targets: Array[Vector2i] = []
var current_target_index: int = 0
var read_progress: float = 0.0
var feedback_text: String = ""

var gaze: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var gaze_vel: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]

## Turn off to keep the chart still (tests).
var shake_enabled: bool = true
var _time: float = 0.0

@onready var target_label: Label = $UI/TargetLabel if has_node("UI/TargetLabel") else null
@onready var feedback_label: Label = $UI/FeedbackLabel if has_node("UI/FeedbackLabel") else null
@onready var read_bar: ProgressBar = $UI/HoldBox/HoldBar if has_node("UI/HoldBox/HoldBar") else null


func _ready() -> void:
	level_id = 2
	level_title = "Level 2: Optic Nerve"
	if targets.is_empty():
		for row in range(CHART_ROWS.size()):
			targets.append(Vector2i(row, randi() % CHART_ROWS[row].length()))
	var center := CHART_RECT.get_center()
	gaze[LEFT] = center + Vector2(-60, 40)
	gaze[RIGHT] = center + Vector2(60, 40)
	feedback_text = "Steer each eye onto the highlighted letter."
	super._ready()
	_update_ui()


func _process(delta: float) -> void:
	if not is_active():
		return
	step(delta, _read_eye_input(LEFT), _read_eye_input(RIGHT))
	_update_ui()
	queue_redraw()


func is_active() -> bool:
	return not GameState.is_game_over and current_target_index < targets.size()


## Chart wobble at the current time (screen-space offset).
func chart_offset() -> Vector2:
	if not shake_enabled:
		return Vector2.ZERO
	return Vector2(
		sin(_time * 1.7) * SHAKE_AMPLITUDE.x + sin(_time * 5.3) * SHAKE_AMPLITUDE.x * 0.3,
		cos(_time * 2.1) * SHAKE_AMPLITUDE.y + sin(_time * 7.1) * SHAKE_AMPLITUDE.y * 0.3
	)


## Where letter `column` of chart row `row` is drawn (screen space, before the chart wobble).
func letter_position(row: int, column: int) -> Vector2:
	var text: String = CHART_ROWS[row]
	var spacing := ROW_FONT_SIZES[row] * 0.9
	var width := spacing * (text.length() - 1)
	var x := CHART_RECT.get_center().x - width / 2.0 + column * spacing
	var y := CHART_RECT.position.y + 50.0 + row * ROW_SPACING
	return Vector2(x, y)


## Current target letter's position, including the chart wobble.
func target_position() -> Vector2:
	var target := targets[_target_slot()]
	return letter_position(target.x, target.y) + chart_offset()


## How close each eye must be to read the current letter (smaller letters, tighter).
func read_radius() -> float:
	return maxf(12.0, ROW_FONT_SIZES[targets[_target_slot()].x] * 0.5)


## Index of the current target, or of the last one once the chart is finished.
func _target_slot() -> int:
	return mini(current_target_index, targets.size() - 1)


## Advances one tick: moves both gaze points with the given stick inputs and applies the rules.
func step(delta: float, input_left: Vector2, input_right: Vector2) -> void:
	if not is_active() or delta <= 0.0:
		return

	_time += delta
	var inputs: Array[Vector2] = [input_left, input_right]
	for eye in [LEFT, RIGHT]:
		# Lazy eyes: each drifts away from the middle (left eye left, right eye right).
		var outward := Vector2(-1.0 if eye == LEFT else 1.0, 0.0) * OUTWARD_DRIFT
		gaze_vel[eye] += (inputs[eye].limit_length(1.0) * GAZE_ACCEL + outward) * delta
		gaze_vel[eye] = gaze_vel[eye].lerp(Vector2.ZERO, clampf(GAZE_FRICTION * delta, 0.0, 1.0))
		gaze[eye] += gaze_vel[eye] * delta

		if not VIEW_RECT.has_point(gaze[eye]):
			gaze[eye] = gaze[eye].clamp(VIEW_RECT.position, VIEW_RECT.end)
			gaze_vel[eye] = Vector2.ZERO
			feedback_text = "The patient's eyes roll off the chart!"
			GameState.add_stress(OFF_CHART_STRESS_PER_SEC * delta)

	if gaze[LEFT].distance_to(gaze[RIGHT]) > CROSS_EYED_DISTANCE:
		feedback_text = "Way too cross-eyed! The patient feels sick."
		GameState.add_stress(CROSS_EYED_STRESS_PER_SEC * delta)

	if is_active():
		_check_reading(delta)


func _check_reading(delta: float) -> void:
	var target := target_position()
	var radius := read_radius()
	var both_on := (
		gaze[LEFT].distance_to(target) <= radius and gaze[RIGHT].distance_to(target) <= radius
	)
	if both_on:
		read_progress = minf(read_progress + delta, READ_TIME)
		if read_progress >= READ_TIME:
			_read_letter()
	else:
		read_progress = maxf(read_progress - READ_DECAY_RATE * delta, 0.0)


func _read_letter() -> void:
	var target := targets[current_target_index]
	var letter := CHART_ROWS[target.x][target.y]
	feedback_text = '"%s!" Correct.' % letter
	react({"smile_l": 0.6, "smile_r": 0.6}, 0.5)
	read_progress = 0.0
	current_target_index += 1
	if current_target_index >= targets.size():
		feedback_text = "20/20 vision! Cranial nerve II checks out."
		win_level()


func _read_eye_input(eye: int) -> Vector2:
	var dir := Vector2.ZERO
	if eye == LEFT:
		dir.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
		dir.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	else:
		dir.x = float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT))
		dir.y = float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))

	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		var axis_x := JOY_AXIS_LEFT_X if eye == LEFT else JOY_AXIS_RIGHT_X
		var axis_y := JOY_AXIS_LEFT_Y if eye == LEFT else JOY_AXIS_RIGHT_Y
		var stick := Vector2(
			Input.get_joy_axis(pads[0], axis_x), Input.get_joy_axis(pads[0], axis_y)
		)
		if stick.length() > JOY_DEADZONE:
			dir += stick
	return dir.limit_length(1.0)


func _update_ui() -> void:
	if info_label:
		info_label.text = (
			"Level 2: Optic Nerve\nLetters read: %d / %d" % [current_target_index, targets.size()]
		)
	if controls_label:
		controls_label.text = "Left eye: W/A/S/D | Right eye: Arrow keys (or gamepad sticks)"
	if target_label:
		if current_target_index < targets.size():
			target_label.text = (
				"Get both eyes on the highlighted letter (row %d)"
				% [targets[current_target_index].x + 1]
			)
		else:
			target_label.text = "Chart complete!"
	if feedback_label:
		feedback_label.text = feedback_text
	if read_bar:
		read_bar.value = read_progress / READ_TIME * 100.0


func _draw() -> void:
	draw_backdrop()

	# The patient's eyes point where you aim them; cross-eyed when the aims diverge.
	# "Left eye" is the one on the left of the screen, to match the left-hand keys.
	var looks: Array[Vector2] = []
	for eye in [LEFT, RIGHT]:
		var rel: Vector2 = gaze[eye] - VIEW_RECT.get_center()
		var look := Vector2(rel.x / (VIEW_RECT.size.x * 0.5), rel.y / (VIEW_RECT.size.y * 0.5))
		looks.append(look.limit_length(1.0))
	PatientKit.draw_patient(
		self, FACE_CENTER, FACE_SCALE, patient_face({"look_l": looks[LEFT], "look_r": looks[RIGHT]})
	)

	_draw_view_panel()
	draw_hud_bands(145.0, 0.0)
	draw_rect(Rect2(Vector2(30, 214), Vector2(70, 220)), Color(0.06, 0.08, 0.07, 0.72))


## The patient's view: one chart copy per eye, shifted by that eye's aim error.
func _draw_view_panel() -> void:
	draw_rect(VIEW_RECT.grow(6), PatientKit.FRAME)
	draw_rect(VIEW_RECT, Color(0.2, 0.22, 0.2))
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		VIEW_RECT.position + Vector2(10, 22),
		"PATIENT'S VIEW",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(0.8, 0.9, 0.8)
	)

	if current_target_index >= targets.size():
		_draw_chart(chart_offset(), 1.0)
		return

	var target := target_position()
	for eye in [LEFT, RIGHT]:
		var error: Vector2 = gaze[eye] - target
		_draw_chart(chart_offset() - error, 0.5)

	# Gaze markers for each eye
	var colors: Array[Color] = [Color(0.3, 0.6, 1.0, 0.9), Color(1.0, 0.5, 0.3, 0.9)]
	for eye in [LEFT, RIGHT]:
		draw_arc(gaze[eye], 9.0, 0.0, TAU, 20, colors[eye], 2.5)
		draw_string(
			font,
			gaze[eye] + Vector2(-4, -12),
			"L" if eye == LEFT else "R",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			colors[eye]
		)

	var hold := read_progress / READ_TIME
	if hold > 0.0:
		draw_arc(
			target,
			read_radius() + 6.0,
			-PI / 2.0,
			-PI / 2.0 + TAU * hold,
			32,
			Color(0.4, 1, 0.4),
			3.0
		)


## Draws the chart shifted by `offset` at opacity `alpha`; highlights the current target.
func _draw_chart(offset: Vector2, alpha: float) -> void:
	var font := ThemeDB.fallback_font
	var board := Rect2(CHART_RECT.position + offset, CHART_RECT.size)
	draw_rect(board, Color(0.97, 0.97, 0.94, alpha))
	for row in range(CHART_ROWS.size()):
		var text: String = CHART_ROWS[row]
		var size: int = ROW_FONT_SIZES[row]
		for column in range(text.length()):
			var color := Color(0.1, 0.1, 0.1, alpha)
			if (
				current_target_index < targets.size()
				and targets[current_target_index] == Vector2i(row, column)
			):
				color = Color(0.85, 0.15, 0.1, alpha)
			var pos := letter_position(row, column) + offset
			var glyph_size := font.get_string_size(
				text[column], HORIZONTAL_ALIGNMENT_LEFT, -1, size
			)
			draw_string(
				font,
				pos + Vector2(-glyph_size.x / 2.0, size * 0.35),
				text[column],
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				size,
				color
			)
