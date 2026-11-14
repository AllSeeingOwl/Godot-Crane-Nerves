class_name Level3EyeMovement
extends BaseLevel

## Level 3: Eye Movement Exam (Cranial Nerves III, IV, VI) - QWOP-style H-pattern
## You work the doctor's arm joint by joint to trace an 'H' with a penlight in front of the
## patient, whose eyes follow the light.
## Mechanics:
## - Q / W swing the shoulder, O / P bend the elbow. Joints have momentum and the arm sags
##   under gravity, so the penlight tip moves in awkward arcs.
## - Visit the six H points in order (within HIT_RADIUS) to trace the pattern.
## - Getting the light close to an eye adds stress; touching an eye is an instant loss.
##   Whipping the light faster than FAST_SPEED (too fast to follow) adds stress.
## - Win condition: all 6 points traced. Lose condition: eye poked or stress >= 100.

enum Phase { TRACING, COMPLETED, FAILED }

const FACE_CENTER: Vector2 = Vector2(576, 330)
const FACE_SCALE: float = 110.0

## H points in PatientKit head units around FACE_CENTER: left column top -> bottom -> middle,
## crossbar (at chin height, clear of the eyes), right column top -> bottom.
const NODES: Array[Vector2] = [
	Vector2(-1.9, -0.6),
	Vector2(-1.9, 2.4),
	Vector2(-1.9, 0.9),
	Vector2(1.9, 0.9),
	Vector2(1.9, -0.6),
	Vector2(1.9, 2.4)
]
const HIT_RADIUS: float = 30.0

# --- The doctor's arm (reaches in from the right, elbow raised) ---
const SHOULDER: Vector2 = Vector2(1180, 520)
const UPPER_ARM: float = 460.0
const FOREARM: float = 440.0
const SHOULDER_MIN: float = -4.2
const SHOULDER_MAX: float = 0.3
const ELBOW_MIN: float = -2.8
const ELBOW_MAX: float = -0.1
const JOINT_ACCEL: float = 3.0
const JOINT_DAMPING: float = 3.0
const GRAVITY: float = 0.8

# --- Hazards ---
const POKE_RADIUS: float = 18.0
const NEAR_EYE_RADIUS: float = 50.0
const NEAR_EYE_STRESS_PER_SEC: float = 12.0
const FAST_SPEED: float = 700.0
const FAST_STRESS_PER_SEC: float = 6.0
const POKE_REASON: String = "You poked the patient in the eye!"

const TRAIL_LENGTH: int = 90
const COAT := Color(0.96, 0.96, 0.98)
const COAT_SHADE := Color(0.78, 0.8, 0.85)

var phase: Phase = Phase.TRACING
var current_node_index: int = 0
var progress: float = 0.0
var feedback_text: String = ""

## Shoulder angle (absolute, radians; 0 = pointing right, -PI/2 = up) and elbow bend
## (negative = bent with the elbow raised; closer to 0 = straighter).
var shoulder_angle: float = -1.57
var elbow_angle: float = -2.45
var shoulder_vel: float = 0.0
var elbow_vel: float = 0.0
var tip_speed: float = 0.0
var trail: Array[Vector2] = []

var _prev_tip: Vector2 = Vector2.ZERO

@onready
var progress_bar: ProgressBar = $UI/HoldBox/HoldBar if has_node("UI/HoldBox/HoldBar") else null
@onready var target_label: Label = $UI/TargetLabel if has_node("UI/TargetLabel") else null
@onready var feedback_label: Label = $UI/FeedbackLabel if has_node("UI/FeedbackLabel") else null


func _ready() -> void:
	level_id = 3
	level_title = "Level 3: Eye Movement"
	_prev_tip = tip_position()
	feedback_text = "Q/W swing the shoulder, O/P bend the elbow. Trace the H!"
	super._ready()
	_update_ui()


func _process(delta: float) -> void:
	if not is_active():
		return
	var shoulder_input := float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_Q))
	var elbow_input := float(Input.is_key_pressed(KEY_P)) - float(Input.is_key_pressed(KEY_O))
	step(delta, shoulder_input, elbow_input)
	_update_ui()
	queue_redraw()


func is_active() -> bool:
	return not GameState.is_game_over and phase == Phase.TRACING


func node_position(index: int) -> Vector2:
	return FACE_CENTER + NODES[index] * FACE_SCALE


func elbow_position() -> Vector2:
	return SHOULDER + Vector2.from_angle(shoulder_angle) * UPPER_ARM


func tip_position() -> Vector2:
	return elbow_position() + Vector2.from_angle(shoulder_angle + elbow_angle) * FOREARM


func eye_positions() -> Array[Vector2]:
	var eyes: Array[Vector2] = []
	eyes.append(PatientKit.feature_point(FACE_CENTER, FACE_SCALE, "eye_l"))
	eyes.append(PatientKit.feature_point(FACE_CENTER, FACE_SCALE, "eye_r"))
	return eyes


## Advances one tick. Inputs are -1..1: +shoulder swings clockwise, +elbow straightens.
func step(delta: float, shoulder_input: float, elbow_input: float) -> void:
	if not is_active() or delta <= 0.0:
		return

	var damping := clampf(JOINT_DAMPING * delta, 0.0, 1.0)
	# Gravity pulls the upper arm toward hanging straight down.
	shoulder_vel += (
		(clampf(shoulder_input, -1, 1) * JOINT_ACCEL + GRAVITY * cos(shoulder_angle)) * delta
	)
	shoulder_vel *= 1.0 - damping
	elbow_vel += clampf(elbow_input, -1, 1) * JOINT_ACCEL * delta
	elbow_vel *= 1.0 - damping
	shoulder_angle += shoulder_vel * delta
	elbow_angle += elbow_vel * delta

	if shoulder_angle < SHOULDER_MIN or shoulder_angle > SHOULDER_MAX:
		shoulder_angle = clampf(shoulder_angle, SHOULDER_MIN, SHOULDER_MAX)
		shoulder_vel = 0.0
	if elbow_angle < ELBOW_MIN or elbow_angle > ELBOW_MAX:
		elbow_angle = clampf(elbow_angle, ELBOW_MIN, ELBOW_MAX)
		elbow_vel = 0.0

	var tip := tip_position()
	tip_speed = tip.distance_to(_prev_tip) / delta
	_prev_tip = tip
	trail.append(tip)
	if trail.size() > TRAIL_LENGTH:
		trail.pop_front()

	_check_hazards(tip, delta)
	if is_active():
		check_current_node()


func _check_hazards(tip: Vector2, delta: float) -> void:
	var nearest := INF
	for eye in eye_positions():
		nearest = minf(nearest, tip.distance_to(eye))

	if nearest <= POKE_RADIUS:
		phase = Phase.FAILED
		feedback_text = POKE_REASON
		react({"eye_closed_l": 1.0, "eye_closed_r": 1.0, "jaw_open": 1.0}, 2.0)
		lose_level(POKE_REASON)
		return

	if nearest <= NEAR_EYE_RADIUS:
		feedback_text = "Careful! That's right in the patient's eye."
		GameState.add_stress(NEAR_EYE_STRESS_PER_SEC * delta)
	elif tip_speed > FAST_SPEED:
		feedback_text = "Too fast! The patient's eyes can't keep up."
		GameState.add_stress(FAST_STRESS_PER_SEC * delta)


## Advances to the next point if the penlight is within range of the current one.
func check_current_node() -> void:
	if current_node_index >= NODES.size():
		return

	if tip_position().distance_to(node_position(current_node_index)) <= HIT_RADIUS:
		current_node_index += 1
		progress = (float(current_node_index) / float(NODES.size())) * 100.0
		feedback_text = "Point %d traced." % current_node_index
		_update_ui()

		if current_node_index >= NODES.size():
			phase = Phase.COMPLETED
			feedback_text = "Smooth pursuit intact. Nerves III, IV and VI check out!"
			win_level()


## Sets the arm pose so the penlight tip sits at `point` (elbow raised).
## Returns false if the point is out of reach. Used by tests.
func reach_toward(point: Vector2) -> bool:
	var offset := point - SHOULDER
	var dist := offset.length()
	var cos_bend := (
		(dist * dist - UPPER_ARM * UPPER_ARM - FOREARM * FOREARM) / (2.0 * UPPER_ARM * FOREARM)
	)
	if cos_bend < -1.0 or cos_bend > 1.0:
		return false
	var bend := -acos(cos_bend)
	var base := offset.angle() - atan2(FOREARM * sin(bend), UPPER_ARM + FOREARM * cos(bend))
	if base > SHOULDER_MAX:
		base -= TAU
	elif base < SHOULDER_MIN:
		base += TAU
	shoulder_angle = base
	elbow_angle = bend
	shoulder_vel = 0.0
	elbow_vel = 0.0
	_prev_tip = tip_position()
	return true


func _update_ui() -> void:
	if info_label:
		info_label.text = (
			"Level 3: Eye Movement\nPoints traced: %d / %d" % [current_node_index, NODES.size()]
		)
	if controls_label:
		controls_label.text = "Shoulder: Q / W | Elbow: O / P"
	if target_label:
		if current_node_index < NODES.size():
			target_label.text = (
				"Trace the H: move the penlight to point %d" % (current_node_index + 1)
			)
		else:
			target_label.text = "H traced!"
	if feedback_label:
		feedback_label.text = feedback_text
	if progress_bar:
		progress_bar.value = progress


func _draw() -> void:
	draw_backdrop()

	# The patient's eyes follow the light.
	var look := (tip_position() - FACE_CENTER) / (FACE_SCALE * 2.0)
	look = look.limit_length(1.0)
	PatientKit.draw_patient(
		self, FACE_CENTER, FACE_SCALE, patient_face({"look_l": look, "look_r": look})
	)

	_draw_h_guide()

	# Light trail
	for i in range(1, trail.size()):
		var alpha := float(i) / float(trail.size())
		draw_line(trail[i - 1], trail[i], Color(1.0, 0.95, 0.6, alpha * 0.7), 3.0)

	_draw_arm()
	draw_hud_bands(145.0, 0.0)
	draw_rect(Rect2(Vector2(30, 214), Vector2(70, 220)), Color(0.06, 0.08, 0.07, 0.72))


## Faint H outline, ticks for traced points and a pulsing ring on the next one.
func _draw_h_guide() -> void:
	var guide := Color(1, 1, 1, 0.25)
	draw_line(node_position(0), node_position(1), guide, 2.0)
	draw_line(node_position(4), node_position(5), guide, 2.0)
	draw_line(node_position(2), node_position(3), guide, 2.0)
	for i in range(NODES.size()):
		var pos := node_position(i)
		if i < current_node_index:
			draw_circle(pos, 8.0, Color(0.2, 0.8, 0.3, 0.9))
		elif i == current_node_index:
			var pulse := 1.0 + 0.12 * sin(Time.get_ticks_msec() / 150.0)
			draw_arc(pos, HIT_RADIUS * pulse, 0.0, TAU, 32, Color(1, 0.9, 0.2), 3.0)
		else:
			draw_circle(pos, 5.0, Color(1, 1, 1, 0.35))


## White-coat sleeve, hand and penlight with its glow.
func _draw_arm() -> void:
	var elbow := elbow_position()
	var tip := tip_position()
	var wrist := tip - Vector2.from_angle(shoulder_angle + elbow_angle) * 34.0
	draw_line(SHOULDER, elbow, COAT_SHADE, 58.0)
	draw_line(SHOULDER, elbow, COAT, 50.0)
	draw_circle(elbow, 25.0, COAT)
	draw_line(elbow, wrist, COAT, 40.0)
	draw_circle(wrist, 17.0, PatientKit.SKIN)
	draw_line(wrist, tip, Color(0.25, 0.25, 0.3), 7.0)
	draw_circle(tip, 14.0, Color(1.0, 0.95, 0.6, 0.35))
	draw_circle(tip, 5.0, Color(1.0, 1.0, 0.85))
