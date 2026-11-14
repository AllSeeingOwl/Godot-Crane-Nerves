class_name Level1Olfactory
extends BaseLevel

## Level 1: Olfactory Nerve Exam
## Mechanics:
## 1. QWER keys select vials / drop vial (Q=Coffee, W=Mint, E=Surströmming, R=Drop)
## 2. A/D keys shift hand position horizontally for fine adjustment
## 3. Mouse cursor is followed with lag/delay
## 4. Movement speed exceeding threshold generates patient stress
## 5. Proximity to nose with good vial identifies smell (win = 2 good smells identified)
## 6. Proximity to nose with bad vial causes evasion and rapid stress increase

const VIALS = {
	"coffee": {"name": "Coffee", "color": Color(0.6, 0.3, 0.0), "type": "good"},
	"mint": {"name": "Mint", "color": Color(0.2, 0.8, 0.4), "type": "good"},
	"surstromming": {"name": "Surströmming", "color": Color(0.8, 0.6, 0.0), "type": "bad"}
}

const SPEED_THRESHOLD: float = 600.0
const SPEED_STRESS_FACTOR: float = 0.01
const BAD_SMELL_STRESS_RATE: float = 12.0
const TIME_STRESS_RATE: float = 1.2
const BAD_SMELL_EVADE_RANGE: float = 300.0
const BAD_SMELL_STRESS_RANGE: float = 150.0
const SMELL_RANGE: float = 100.0
const LAG_SPEED: float = 8.0
const KEYBOARD_MOVE_SPEED: float = 300.0

## Size of the patient's head; the head is drawn so its nose sits on the wandering nose.
const HEAD_SCALE: float = 85.0
const GLASS := Color(0.85, 0.92, 0.95, 0.55)
const STINK := Color(0.45, 0.6, 0.15, 0.7)
const AROMA := Color(1.0, 1.0, 1.0, 0.55)

var selected_vial: String = ""
var identified_vials: Array[String] = []
var hand_position: Vector2 = Vector2.ZERO
var hand_velocity: Vector2 = Vector2.ZERO
var hand_keyboard_offset: Vector2 = Vector2.ZERO
var nose_velocity: Vector2 = Vector2.ZERO
var progress: float = 0.0
var current_hand_speed: float = 0.0

var _target_mouse_pos: Vector2 = Vector2.ZERO

@onready var nose: Control = $Nose
@onready var nose_progress: ProgressBar = $Nose/ProgressBar
@onready var vial_cursor: Control = $VialCursor
@onready var vial_cursor_color: ColorRect = $VialCursor/ColorRect


func _ready() -> void:
	level_id = 1
	level_title = "Level 1: Olfactory Nerve"
	super._ready()

	var screen_size = get_viewport_rect().size
	if screen_size == Vector2.ZERO:
		screen_size = Vector2(1152, 648)

	# Position nose near upper middle of screen
	if nose:
		nose.position = Vector2(screen_size.x / 2.0, screen_size.y / 2.0 - 100.0)
	_target_mouse_pos = get_global_mouse_position()
	hand_position = get_global_mouse_position()

	# Initial random velocity for nose
	nose_velocity = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * 100.0

	# Connect UI buttons
	if has_node("UI/VialsBox/CoffeeBtn"):
		$UI/VialsBox/CoffeeBtn.pressed.connect(_on_vial_pressed.bind("coffee"))
	if has_node("UI/VialsBox/MintBtn"):
		$UI/VialsBox/MintBtn.pressed.connect(_on_vial_pressed.bind("mint"))
	if has_node("UI/VialsBox/SurstrommingBtn"):
		$UI/VialsBox/SurstrommingBtn.pressed.connect(_on_vial_pressed.bind("surstromming"))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_target_mouse_pos = event.position

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q:
				_on_vial_pressed("coffee")
			KEY_W:
				_on_vial_pressed("mint")
			KEY_E:
				_on_vial_pressed("surstromming")
			KEY_R:
				selected_vial = ""
				_update_ui()


func _on_vial_pressed(vial_id: String) -> void:
	if identified_vials.has(vial_id):
		return

	if selected_vial == vial_id:
		selected_vial = ""
	else:
		selected_vial = vial_id

	_update_ui()


func _update_ui() -> void:
	if info_label:
		info_label.text = "Level 1: Olfactory Nerve\nIdentified: %d / 2" % identified_vials.size()

	if controls_label:
		controls_label.text = (
			"Controls: Q (Coffee) | W (Mint) | E (Surströmming) | R (Drop)\n"
			+ "A/D (Shift Hand) | Mouse (Move Hand with Lag)"
		)

	# Update button visual state
	if has_node("UI/VialsBox/CoffeeBtn"):
		_update_btn_state($UI/VialsBox/CoffeeBtn, "coffee")
	if has_node("UI/VialsBox/MintBtn"):
		_update_btn_state($UI/VialsBox/MintBtn, "mint")
	if has_node("UI/VialsBox/SurstrommingBtn"):
		_update_btn_state($UI/VialsBox/SurstrommingBtn, "surstromming")

	if selected_vial != "":
		if vial_cursor:
			vial_cursor.visible = true
		if vial_cursor_color and VIALS.has(selected_vial):
			vial_cursor_color.color = VIALS[selected_vial].color
	else:
		if vial_cursor:
			vial_cursor.visible = false


func _update_btn_state(btn: Button, vial_id: String) -> void:
	if identified_vials.has(vial_id):
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5)
	else:
		btn.disabled = false
		if selected_vial == vial_id:
			btn.modulate = Color(1.2, 1.2, 0.5)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)


func _process(delta: float) -> void:
	if GameState.is_game_over:
		return

	# 1. Keyboard Controls (A/D keys for precise hand offset)
	if Input.is_key_pressed(KEY_A):
		hand_keyboard_offset.x -= KEYBOARD_MOVE_SPEED * delta
	if Input.is_key_pressed(KEY_D):
		hand_keyboard_offset.x += KEYBOARD_MOVE_SPEED * delta

	# 2. Mouse Following with Lag/Delay Effect (frame-rate independent lerp & instant event position)
	var target_hand_pos = _target_mouse_pos + hand_keyboard_offset
	var prev_hand_pos = hand_position
	var lerp_factor = clamp(1.0 - exp(-LAG_SPEED * delta), 0.0, 1.0)
	hand_position = hand_position.lerp(target_hand_pos, lerp_factor)

	if delta > 0.0:
		hand_velocity = (hand_position - prev_hand_pos) / delta
		current_hand_speed = hand_velocity.length()

	# 3. Speed-based Stress Calculation
	if current_hand_speed > SPEED_THRESHOLD:
		var speed_excess = current_hand_speed - SPEED_THRESHOLD
		GameState.add_stress(speed_excess * SPEED_STRESS_FACTOR * delta)

	# 4. Wandering Nose Position
	if nose:
		var nose_center = nose.position + (nose.size / 2.0 if nose is Control else Vector2.ZERO)
		nose.position += nose_velocity * delta

		# Bounce nose off screen edges
		var screen_size = get_viewport_rect().size
		if screen_size == Vector2.ZERO:
			screen_size = Vector2(1152, 648)
		var margin = 100.0

		if nose.position.x < margin:
			nose.position.x = margin
			nose_velocity.x *= -1.0
		elif nose.position.x > screen_size.x - margin:
			nose.position.x = screen_size.x - margin
			nose_velocity.x *= -1.0

		if nose.position.y < margin:
			nose.position.y = margin
			nose_velocity.y *= -1.0
		elif nose.position.y > screen_size.y - margin:
			nose.position.y = screen_size.y - margin
			nose_velocity.y *= -1.0

		# Random direction changes for nose
		if randf() < 0.02:
			nose_velocity += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 50.0
			if nose_velocity.length() > 200.0:
				nose_velocity = nose_velocity.normalized() * 200.0

		# 5. Hand / Vial Logic & Proximity Calculation
		if vial_cursor:
			vial_cursor.position = hand_position

		if selected_vial != "":
			var vial_def = VIALS[selected_vial]
			var dist = hand_position.distance_to(nose_center)

			if not identified_vials.has(selected_vial):
				if vial_def["type"] == "bad":
					# Bad smell (Surströmming) causes patient evasion
					if dist < BAD_SMELL_EVADE_RANGE and dist > 0.1:
						var evade_dir = (nose_center - hand_position).normalized()
						nose_velocity += evade_dir * 300.0 * delta

					# Rapid stress increase if bad smell is too close
					if dist < BAD_SMELL_STRESS_RANGE:
						GameState.add_stress(BAD_SMELL_STRESS_RATE * delta)

				if dist < SMELL_RANGE:
					# Inside smelling range
					progress += 50.0 * delta

					# Slowly increase stress taking time near patient
					GameState.add_stress(TIME_STRESS_RATE * delta)

					if progress >= 100.0:
						identified_vials.append(selected_vial)
						selected_vial = ""
						progress = 0.0
						_update_ui()
						_check_win_condition()
				else:
					if progress > 0.0:
						progress = max(0.0, progress - 100.0 * delta)
		else:
			if progress > 0.0:
				progress = max(0.0, progress - 100.0 * delta)

		# Update Nose progress bar
		if nose_progress:
			if progress > 0.0:
				nose_progress.visible = true
				nose_progress.value = progress
			else:
				nose_progress.visible = false

	queue_redraw()


func nose_center() -> Vector2:
	return nose.position + nose.size / 2.0 if nose else Vector2.ZERO


func _draw() -> void:
	draw_backdrop()
	if not nose:
		return

	var nose_pos := nose_center()
	var head_center: Vector2 = nose_pos - PatientKit.FEATURES["nose"] * HEAD_SCALE
	PatientKit.draw_patient(self, head_center, HEAD_SCALE, patient_face(_smell_face(nose_pos)))

	_draw_hand_and_vial(hand_position)
	draw_hud_bands(110.0, 92.0)


## The patient's reaction to whatever is being waved under their nose.
func _smell_face(nose_pos: Vector2) -> Dictionary:
	var to_hand := (hand_position - nose_pos) / (HEAD_SCALE * 3.0)
	var face := {"look_l": to_hand.limit_length(1.0), "look_r": to_hand.limit_length(1.0)}
	if selected_vial == "" or not VIALS.has(selected_vial):
		return face

	var dist := hand_position.distance_to(nose_pos)
	if VIALS[selected_vial]["type"] == "bad" and dist < BAD_SMELL_STRESS_RANGE:
		face.merge(
			{
				"nose_wrinkle": 1.0,
				"brow_raise": -1.0,
				"eye_closed_l": 0.6,
				"eye_closed_r": 0.6,
				"smile_l": -1.0,
				"smile_r": -1.0
			},
			true
		)
	elif dist < SMELL_RANGE:
		face.merge({"eye_closed_l": 0.7, "eye_closed_r": 0.7, "smile_l": 0.6, "smile_r": 0.6}, true)
	return face


## The doctor's gloved hand holding a test tube of the selected smell.
func _draw_hand_and_vial(pos: Vector2) -> void:
	var cuff := pos + Vector2(26, 34)
	draw_line(cuff + Vector2(30, 40), cuff, Color(0.96, 0.96, 0.98), 30.0)
	draw_circle(pos + Vector2(14, 16), 18.0, Color(0.75, 0.85, 0.95))

	if selected_vial == "" or not VIALS.has(selected_vial):
		return

	var liquid: Color = VIALS[selected_vial]["color"]
	var tube := Rect2(pos + Vector2(-9, -34), Vector2(18, 46))
	draw_rect(tube, GLASS)
	draw_rect(Rect2(tube.position + Vector2(2, 18), Vector2(14, 26)), liquid)
	draw_circle(tube.position + Vector2(9, 44), 9.0, liquid)
	draw_rect(Rect2(tube.position + Vector2(-1, -8), Vector2(20, 9)), Color(0.6, 0.45, 0.3))

	var t := Time.get_ticks_msec() / 300.0
	var is_bad: bool = VIALS[selected_vial]["type"] == "bad"
	for i in range(3):
		var base := tube.position + Vector2(9 + (i - 1) * 10, -12)
		var points := PackedVector2Array()
		for k in range(6):
			var y := -k * 8.0
			points.append(base + Vector2(sin(t + i * 2.0 + k * 0.9) * 5.0, y))
		draw_polyline(points, STINK if is_bad else AROMA, 3.0 if is_bad else 2.0)


func _check_win_condition() -> void:
	var good_identified: int = 0
	for vial in identified_vials:
		if VIALS.has(vial) and VIALS[vial]["type"] == "good":
			good_identified += 1

	if good_identified >= 2:
		win_level()
