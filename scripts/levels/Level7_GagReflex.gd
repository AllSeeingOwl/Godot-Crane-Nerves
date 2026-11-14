class_name Level7GagReflex
extends BaseLevel

## Level 7: Glossopharyngeal & Vagus Nerves (IX & X) - Gag Reflex Exam
## Side-on cut-through of the patient's head: lips on the left, back of the throat on the right.
## Mechanics:
## - W/A/S/D drives the doctor's floaty arm. The mouse steers the tongue depressor angle (laggy).
## - Phase 1 (Depress Tongue): press the tongue down gently for TONGUE_HOLD_TIME seconds.
## - Phase 2 (Elicit Gag): touch the back of the throat GENTLY to trigger the gag reflex and win.
## - The mouth randomly twitches and snaps shut. Being inside when it closes = CHOMP.
## - Hitting the lips, tickling the palate, squashing the tongue, or touching the throat
##   too early / too hard adds stress.
## - Pushing past the throat makes the patient vomit (instant loss).

enum Phase { DEPRESS_TONGUE, ELICIT_GAG, COMPLETED, FAILED }
enum MouthState { OPEN, WARNING, CLOSING, CLOSED, REOPENING }

# --- Geometry (local to the mouth: lips at x = 0, mouth centre at y = 0) ---
const HEAD_ORIGIN: Vector2 = Vector2(560, 400)
const MOUTH_OPEN_GAP: float = 55.0
const PALATE_Y: float = -45.0
const TONGUE_Y: float = 30.0
const TONGUE_ZONE_MIN_X: float = 30.0
const TONGUE_ZONE_MAX_X: float = 170.0
const TONGUE_PRESS_MAX: float = 18.0
const PHARYNX_X: float = 220.0
const GAG_OVERSHOOT: float = 25.0

const DEPRESSOR_LENGTH: float = 250.0
const SHAFT_HALF_THICKNESS: float = 4.0
const MAX_ANGLE: float = PI / 3.0  # 60 degrees

const HAND_START: Vector2 = Vector2(-330, 0)
const HAND_MIN: Vector2 = Vector2(-450, -200)
const HAND_MAX: Vector2 = Vector2(10, 200)

# --- Feel ---
const ARM_ACCEL: float = 500.0
const ARM_FRICTION: float = 4.0
const ANGLE_RESPONSIVENESS: float = 2.5
const TREMOR_AMPLITUDE: float = 3.0
const TREMOR_FREQUENCY: float = 7.0
const RECOIL_DISTANCE: float = 60.0

# --- Rules ---
const TONGUE_HOLD_TIME: float = 1.5
const GENTLE_TOUCH_SPEED: float = 120.0
const HIT_COOLDOWN: float = 0.5

# --- Mouth timing ---
const MOUTH_CLOSE_INTERVAL_MIN: float = 2.5
const MOUTH_CLOSE_INTERVAL_MAX: float = 5.0
const MOUTH_WARNING_TIME: float = 0.5
const MOUTH_CLOSE_SPEED: float = 300.0
const MOUTH_CLOSED_TIME: float = 0.6
const MOUTH_REOPEN_SPEED: float = 60.0

# --- Stress ---
const LIP_HIT_STRESS: float = 6.0
const CHOMP_STRESS: float = 25.0
const PALATE_STRESS_PER_SEC: float = 15.0
const TONGUE_OVERPRESS_STRESS_PER_SEC: float = 20.0
const EARLY_THROAT_STRESS: float = 10.0
const ROUGH_THROAT_STRESS: float = 15.0
const VOMIT_REASON: String = "Pushed too far! The patient vomited all over you."

var phase: Phase = Phase.DEPRESS_TONGUE
var mouth_state: MouthState = MouthState.OPEN
var mouth_gap: float = MOUTH_OPEN_GAP
var mouth_timer: float = 0.0

var hand_pos: Vector2 = HAND_START
var hand_vel: Vector2 = Vector2.ZERO
var depressor_angle: float = 0.0
var tremor_offset: Vector2 = Vector2.ZERO

var tongue_hold_progress: float = 0.0
var tip_velocity: Vector2 = Vector2.ZERO
var feedback_text: String = ""

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _prev_hand_pos: Vector2 = HAND_START
var _prev_tip: Vector2 = Vector2.ZERO
var _touching_throat: bool = false
var _chomped_this_cycle: bool = false
var _hit_cooldown: float = 0.0
var _time: float = 0.0

@onready var phase_label: Label = $UI/PhaseLabel if has_node("UI/PhaseLabel") else null
@onready var feedback_label: Label = $UI/FeedbackLabel if has_node("UI/FeedbackLabel") else null
@onready var tongue_bar: ProgressBar = (
	$UI/TongueBox/TongueBar if has_node("UI/TongueBox/TongueBar") else null
)


func _ready() -> void:
	level_id = 7
	level_title = "Level 7: Gag Reflex"
	rng.randomize()
	mouth_timer = _next_close_interval()
	_prev_tip = get_tip_position()
	super._ready()
	_update_ui()


func _process(delta: float) -> void:
	if not is_active():
		return

	_apply_arm_input(_read_arm_input(), delta)
	_update_angle(get_global_mouse_position() - HEAD_ORIGIN, delta)

	_time += delta
	tremor_offset = (
		Vector2(sin(_time * TREMOR_FREQUENCY), cos(_time * TREMOR_FREQUENCY * 1.3))
		* TREMOR_AMPLITUDE
	)

	step(delta)
	_update_ui()
	queue_redraw()


func is_active() -> bool:
	return not GameState.is_game_over and phase != Phase.COMPLETED and phase != Phase.FAILED


## Tip of the tongue depressor in mouth-local coordinates.
func get_tip_position() -> Vector2:
	return hand_pos + Vector2.from_angle(depressor_angle) * DEPRESSOR_LENGTH + tremor_offset


## Advances the simulation one tick: mouth movement, collisions and exam rules.
func step(delta: float) -> void:
	if not is_active() or delta <= 0.0:
		return

	_hit_cooldown = max(_hit_cooldown - delta, 0.0)
	update_mouth(delta)

	var tip := get_tip_position()
	if _shaft_hits_lips(tip):
		if mouth_state == MouthState.CLOSING or mouth_state == MouthState.CLOSED:
			_chomp()
		else:
			_lip_hit()
		tip = get_tip_position()

	tip_velocity = (tip - _prev_tip) / delta
	_evaluate_tip(tip, delta)

	_prev_tip = get_tip_position()
	_prev_hand_pos = hand_pos


func update_mouth(delta: float) -> void:
	match mouth_state:
		MouthState.OPEN:
			mouth_timer -= delta
			if mouth_timer <= 0.0:
				mouth_state = MouthState.WARNING
				mouth_timer = MOUTH_WARNING_TIME
		MouthState.WARNING:
			mouth_timer -= delta
			if mouth_timer <= 0.0:
				mouth_state = MouthState.CLOSING
				_chomped_this_cycle = false
		MouthState.CLOSING:
			mouth_gap = max(mouth_gap - MOUTH_CLOSE_SPEED * delta, 0.0)
			if mouth_gap <= 0.0:
				mouth_state = MouthState.CLOSED
				mouth_timer = MOUTH_CLOSED_TIME
		MouthState.CLOSED:
			mouth_timer -= delta
			if mouth_timer <= 0.0:
				mouth_state = MouthState.REOPENING
		MouthState.REOPENING:
			mouth_gap = min(mouth_gap + MOUTH_REOPEN_SPEED * delta, MOUTH_OPEN_GAP)
			if mouth_gap >= MOUTH_OPEN_GAP:
				mouth_state = MouthState.OPEN
				mouth_timer = _next_close_interval()


func _read_arm_input() -> Vector2:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0
	return input_dir.normalized() if input_dir != Vector2.ZERO else input_dir


func _apply_arm_input(input_dir: Vector2, delta: float) -> void:
	hand_vel += input_dir * ARM_ACCEL * delta
	hand_vel = hand_vel.lerp(Vector2.ZERO, clamp(ARM_FRICTION * delta, 0.0, 1.0))
	hand_pos += hand_vel * delta
	hand_pos = hand_pos.clamp(HAND_MIN, HAND_MAX)


func _update_angle(mouse_local: Vector2, delta: float) -> void:
	var target := clampf((mouse_local - hand_pos).angle(), -MAX_ANGLE, MAX_ANGLE)
	var weight := 1.0 - exp(-ANGLE_RESPONSIVENESS * delta)
	depressor_angle = lerp_angle(depressor_angle, target, weight)


## True when the depressor shaft passes through the lips outside the open gap.
func _shaft_hits_lips(tip: Vector2) -> bool:
	if tip.x <= 0.0:
		return false
	var cross_y: float = hand_pos.y
	if hand_pos.x < 0.0:
		var t := -hand_pos.x / (tip.x - hand_pos.x)
		cross_y = lerpf(hand_pos.y, tip.y, t)
	return absf(cross_y) + SHAFT_HALF_THICKNESS > mouth_gap


func _lip_hit() -> void:
	hand_pos = _prev_hand_pos
	hand_vel = Vector2.ZERO
	if _shaft_hits_lips(get_tip_position()):
		_recoil()
	if _hit_cooldown <= 0.0:
		feedback_text = "Ow! You jabbed the patient's lips."
		GameState.add_stress(LIP_HIT_STRESS)
		_hit_cooldown = HIT_COOLDOWN


func _chomp() -> void:
	hand_pos = HAND_START
	hand_vel = Vector2.ZERO
	_touching_throat = false
	if not _chomped_this_cycle:
		_chomped_this_cycle = true
		feedback_text = "*CHOMP* The patient bit down on the depressor!"
		GameState.add_stress(CHOMP_STRESS)


func _recoil() -> void:
	hand_pos.x = max(hand_pos.x - RECOIL_DISTANCE, HAND_MIN.x)
	hand_vel = Vector2.ZERO


func _evaluate_tip(tip: Vector2, delta: float) -> void:
	if tip.x <= 0.0:
		_touching_throat = false
		return

	if tip.x > PHARYNX_X + GAG_OVERSHOOT:
		_vomit()
		return

	if tip.x >= PHARYNX_X:
		if not _touching_throat:
			_touching_throat = true
			_on_throat_touched()
		return
	_touching_throat = false

	if tip.y < PALATE_Y:
		feedback_text = "Tickling the roof of the mouth. The patient squirms."
		GameState.add_stress(PALATE_STRESS_PER_SEC * delta)
		return

	var press := tip.y - TONGUE_Y
	if press <= 0.0 or tip.x < TONGUE_ZONE_MIN_X or tip.x > TONGUE_ZONE_MAX_X:
		return

	if press > TONGUE_PRESS_MAX:
		feedback_text = "Too hard! You're squashing the tongue."
		GameState.add_stress(TONGUE_OVERPRESS_STRESS_PER_SEC * delta)
	elif phase == Phase.DEPRESS_TONGUE:
		tongue_hold_progress = min(tongue_hold_progress + delta, TONGUE_HOLD_TIME)
		feedback_text = "Say 'ahhh'..."
		if tongue_hold_progress >= TONGUE_HOLD_TIME:
			phase = Phase.ELICIT_GAG
			feedback_text = "Tongue depressed! Now gently touch the back of the throat."


func _on_throat_touched() -> void:
	if phase == Phase.DEPRESS_TONGUE:
		feedback_text = "Can't see a thing! Depress the tongue first."
		GameState.add_stress(EARLY_THROAT_STRESS)
		_recoil()
		_touching_throat = false
	elif tip_velocity.length() > GENTLE_TOUCH_SPEED:
		feedback_text = "Way too rough! The patient recoils in horror."
		GameState.add_stress(ROUGH_THROAT_STRESS)
		_recoil()
		_touching_throat = false
	else:
		feedback_text = "*HURK* Gag reflex intact. Cranial nerves IX & X check out!"
		phase = Phase.COMPLETED
		win_level()


func _vomit() -> void:
	phase = Phase.FAILED
	feedback_text = VOMIT_REASON
	lose_level(VOMIT_REASON)


func _next_close_interval() -> float:
	return rng.randf_range(MOUTH_CLOSE_INTERVAL_MIN, MOUTH_CLOSE_INTERVAL_MAX)


func _update_ui() -> void:
	if info_label:
		info_label.text = "Level 7: Gag Reflex (IX & X)"

	if phase_label:
		match phase:
			Phase.DEPRESS_TONGUE:
				phase_label.text = "STEP 1: Hold the tongue down gently"
			Phase.ELICIT_GAG:
				phase_label.text = "STEP 2: Gently touch the back of the throat"
			Phase.COMPLETED:
				phase_label.text = "EXAM COMPLETE"
			Phase.FAILED:
				phase_label.text = "EXAM FAILED"

	if feedback_label:
		feedback_label.text = feedback_text

	if tongue_bar:
		tongue_bar.value = tongue_hold_progress / TONGUE_HOLD_TIME * 100.0


func _draw() -> void:
	var o := HEAD_ORIGIN
	var skin := Color(0.95, 0.75, 0.6)
	var flesh := Color(0.55, 0.15, 0.2)
	var lip_color := Color(0.85, 0.35, 0.4)
	if mouth_state == MouthState.WARNING:
		lip_color = Color(1.0, 0.2, 0.2)

	# Head silhouette and oral cavity
	draw_circle(o + Vector2(160, -40), 230.0, skin)
	draw_rect(Rect2(o + Vector2(0, PALATE_Y), Vector2(PHARYNX_X, TONGUE_Y - PALATE_Y)), flesh)

	# Palate, tongue and back of throat
	draw_line(o + Vector2(0, PALATE_Y), o + Vector2(PHARYNX_X, PALATE_Y), Color(1, 0.8, 0.8), 4.0)
	var tongue_width := TONGUE_ZONE_MAX_X - TONGUE_ZONE_MIN_X
	draw_rect(
		Rect2(o + Vector2(TONGUE_ZONE_MIN_X, TONGUE_Y), Vector2(tongue_width, 30)),
		Color(0.9, 0.4, 0.5)
	)
	var throat_color := Color(0.4, 1, 0.4) if phase == Phase.ELICIT_GAG else Color(0.7, 0.2, 0.3)
	draw_line(o + Vector2(PHARYNX_X, PALATE_Y), o + Vector2(PHARYNX_X, TONGUE_Y), throat_color, 6.0)

	# Lips (upper and lower) leave a gap of mouth_gap around y = 0
	draw_rect(Rect2(o + Vector2(-15, -130), Vector2(30, 130 - mouth_gap)), lip_color)
	draw_rect(Rect2(o + Vector2(-15, mouth_gap), Vector2(30, 130 - mouth_gap)), lip_color)

	# Doctor's hand and tongue depressor
	var tip := get_tip_position()
	draw_line(o + hand_pos, o + tip, Color(0.9, 0.85, 0.6), SHAFT_HALF_THICKNESS * 2.0)
	draw_circle(o + hand_pos, 18.0, Color(0.85, 0.9, 1.0))
