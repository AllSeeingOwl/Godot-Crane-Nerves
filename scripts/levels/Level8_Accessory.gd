class_name Level8Accessory
extends BaseLevel

## Level 8: Accessory Nerve (XI) - Shoulder Shrug & Head Turn Against Resistance
## You play both sides at once: the doctor's hands (mouse) and the patient's muscles (arrow keys).
## Mechanics:
## - Left / Right mouse button: doctor presses on the patient's left / right side (hold to ramp up).
## - Left / Right arrow: patient pushes back with the left / right side (hold to ramp up).
## - Each side's displacement drifts toward (patient force - doctor force).
##   Keep every active side within BALANCE_TOLERANCE while the doctor applies at least
##   MIN_TEST_FORCE, for HOLD_TIME seconds, to pass a part.
## - Part 1 (Shrug): both shoulders at once. Part 2 (Turn Left) and Part 3 (Turn Right): one side.
## - The patient's muscles twitch at random. Overpowering either way adds stress; pressing the
##   shoulders unevenly adds stress; overpowering the patient badly is an instant loss.

enum Phase { SHRUG, TURN_LEFT, TURN_RIGHT, COMPLETED, FAILED }

const LEFT: int = 0
const RIGHT: int = 1

# --- Forces (0-100) ---
const PRESS_RATE: float = 70.0
const RELEASE_RATE: float = 90.0
const DISPLACEMENT_RESPONSIVENESS: float = 3.0

# --- Rules ---
const MIN_TEST_FORCE: float = 40.0
const BALANCE_TOLERANCE: float = 10.0
const HOLD_TIME: float = 2.5
const HOLD_DECAY_RATE: float = 0.5
const STRAIN_LIMIT: float = 30.0
const CATASTROPHE_LIMIT: float = 60.0
const UNBALANCED_LIMIT: float = 35.0

# --- Stress ---
const OVERPOWER_STRESS_PER_SEC: float = 12.0
const OVERSHOOT_STRESS_PER_SEC: float = 12.0
const UNBALANCED_STRESS_PER_SEC: float = 10.0

# --- Patient twitches ---
const TWITCH_INTERVAL_MIN: float = 1.0
const TWITCH_INTERVAL_MAX: float = 3.0
const TWITCH_STRENGTH_MIN: float = 15.0
const TWITCH_STRENGTH_MAX: float = 30.0
const TWITCH_DECAY_RATE: float = 25.0

const PHASE_TITLES: Dictionary = {
	Phase.SHRUG: "PART 1: Shrug both shoulders against your hands",
	Phase.TURN_LEFT: "PART 2: Turn head LEFT against your hand",
	Phase.TURN_RIGHT: "PART 3: Turn head RIGHT against your hand",
	Phase.COMPLETED: "EXAM COMPLETE",
	Phase.FAILED: "EXAM FAILED",
}

var phase: Phase = Phase.SHRUG
var doctor_force: Array[float] = [0.0, 0.0]
var patient_force: Array[float] = [0.0, 0.0]
var twitch: Array[float] = [0.0, 0.0]
var displacement: Array[float] = [0.0, 0.0]
var hold_progress: float = 0.0
var twitch_timer: float = 0.0
var feedback_text: String = ""

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var phase_label: Label = $UI/PhaseLabel if has_node("UI/PhaseLabel") else null
@onready var feedback_label: Label = $UI/FeedbackLabel if has_node("UI/FeedbackLabel") else null
@onready var hold_bar: ProgressBar = $UI/HoldBox/HoldBar if has_node("UI/HoldBox/HoldBar") else null


func _ready() -> void:
	level_id = 8
	level_title = "Level 8: Accessory Nerve"
	rng.randomize()
	twitch_timer = _next_twitch_interval()
	super._ready()
	_update_ui()


func _process(delta: float) -> void:
	if not is_active():
		return

	apply_inputs(
		[
			Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),
			Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT),
		],
		[Input.is_key_pressed(KEY_LEFT), Input.is_key_pressed(KEY_RIGHT)],
		delta
	)
	step(delta)
	_update_ui()
	queue_redraw()


func is_active() -> bool:
	return not GameState.is_game_over and phase != Phase.COMPLETED and phase != Phase.FAILED


## Sides that matter in the current phase.
func active_sides() -> Array:
	match phase:
		Phase.SHRUG:
			return [LEFT, RIGHT]
		Phase.TURN_LEFT:
			return [LEFT]
		Phase.TURN_RIGHT:
			return [RIGHT]
	return []


## Ramps forces up while held and down while released. Arrays are [left, right].
func apply_inputs(doctor_held: Array, patient_held: Array, delta: float) -> void:
	for side in [LEFT, RIGHT]:
		doctor_force[side] = _ramp(doctor_force[side], doctor_held[side], delta)
		patient_force[side] = _ramp(patient_force[side], patient_held[side], delta)


func effective_patient_force(side: int) -> float:
	return clampf(patient_force[side] + twitch[side], 0.0, 100.0)


## Advances the simulation one tick: twitches, displacement and exam rules.
func step(delta: float) -> void:
	if not is_active() or delta <= 0.0:
		return

	_update_twitches(delta)

	var weight := 1.0 - exp(-DISPLACEMENT_RESPONSIVENESS * delta)
	for side in [LEFT, RIGHT]:
		var target: float = effective_patient_force(side) - doctor_force[side]
		displacement[side] = lerpf(displacement[side], target, weight)

	_evaluate(delta)


func _ramp(value: float, held: bool, delta: float) -> float:
	if held:
		return minf(value + PRESS_RATE * delta, 100.0)
	return maxf(value - RELEASE_RATE * delta, 0.0)


func _update_twitches(delta: float) -> void:
	for side in [LEFT, RIGHT]:
		twitch[side] = move_toward(twitch[side], 0.0, TWITCH_DECAY_RATE * delta)

	twitch_timer -= delta
	if twitch_timer <= 0.0:
		var side: int = rng.randi_range(LEFT, RIGHT)
		var strength: float = rng.randf_range(TWITCH_STRENGTH_MIN, TWITCH_STRENGTH_MAX)
		twitch[side] += strength if rng.randf() < 0.5 else -strength
		twitch_timer = _next_twitch_interval()


func _evaluate(delta: float) -> void:
	var sides: Array = active_sides()
	var balanced := true
	var problem := ""

	for side in sides:
		var disp: float = displacement[side]
		if disp < -CATASTROPHE_LIMIT:
			_fail(_catastrophe_reason())
			return
		if disp < -STRAIN_LIMIT:
			problem = _overpower_text()
			GameState.add_stress(OVERPOWER_STRESS_PER_SEC * delta)
		elif disp > STRAIN_LIMIT:
			problem = _overshoot_text()
			GameState.add_stress(OVERSHOOT_STRESS_PER_SEC * delta)

		if absf(disp) > BALANCE_TOLERANCE or doctor_force[side] < MIN_TEST_FORCE:
			balanced = false

	if phase == Phase.SHRUG:
		if absf(doctor_force[LEFT] - doctor_force[RIGHT]) > UNBALANCED_LIMIT:
			problem = "Unbalanced pressure! The patient tilts like a leaning tower."
			GameState.add_stress(UNBALANCED_STRESS_PER_SEC * delta)
			balanced = false

	if not is_active():
		return

	if balanced:
		hold_progress = minf(hold_progress + delta, HOLD_TIME)
		feedback_text = "Steady... good resistance."
		if hold_progress >= HOLD_TIME:
			_advance_phase()
	else:
		hold_progress = maxf(hold_progress - HOLD_DECAY_RATE * delta, 0.0)
		feedback_text = problem if not problem.is_empty() else _hint_text()


func _advance_phase() -> void:
	hold_progress = 0.0
	doctor_force.fill(0.0)
	patient_force.fill(0.0)
	twitch.fill(0.0)
	displacement.fill(0.0)

	match phase:
		Phase.SHRUG:
			phase = Phase.TURN_LEFT
			feedback_text = "Shoulders pass! Now the head turn."
		Phase.TURN_LEFT:
			phase = Phase.TURN_RIGHT
			feedback_text = "Left turn passes! Now the other way."
		Phase.TURN_RIGHT:
			phase = Phase.COMPLETED
			feedback_text = "Strong and symmetrical. Cranial nerve XI checks out!"
			win_level()


func _fail(reason: String) -> void:
	phase = Phase.FAILED
	feedback_text = reason
	lose_level(reason)


func _catastrophe_reason() -> String:
	if phase == Phase.SHRUG:
		return "*POP* You dislocated the patient's shoulder."
	return "*CRACK* Necks are not supposed to turn that way."


func _overpower_text() -> String:
	if phase == Phase.SHRUG:
		return "Too hard! You're crushing the shoulder."
	return "Too hard! You're wrenching the patient's head."


func _overshoot_text() -> String:
	if phase == Phase.SHRUG:
		return "The shoulder shoots up and clips your chin!"
	return "The patient's head whips round and headbutts your hand!"


func _hint_text() -> String:
	if phase == Phase.SHRUG:
		return "Press both shoulders firmly while the patient shrugs back evenly."
	return "Push against the cheek while the patient turns into your hand."


func _next_twitch_interval() -> float:
	return rng.randf_range(TWITCH_INTERVAL_MIN, TWITCH_INTERVAL_MAX)


func _update_ui() -> void:
	if info_label:
		info_label.text = "Level 8: Accessory Nerve (XI)"

	if phase_label:
		phase_label.text = PHASE_TITLES[phase]

	if feedback_label:
		feedback_label.text = feedback_text

	if hold_bar:
		hold_bar.value = hold_progress / HOLD_TIME * 100.0


func _draw() -> void:
	var center := Vector2(576, 400)
	var skin := Color(0.95, 0.75, 0.6)
	var sides: Array = active_sides()

	# Shoulders rise with displacement during the shrug.
	var shrug_l: float = -displacement[LEFT] if phase == Phase.SHRUG else 0.0
	var shrug_r: float = -displacement[RIGHT] if phase == Phase.SHRUG else 0.0
	draw_rect(Rect2(center + Vector2(-220, 60 + shrug_l), Vector2(180, 50)), skin)
	draw_rect(Rect2(center + Vector2(40, 60 + shrug_r), Vector2(180, 50)), skin)
	draw_rect(Rect2(center + Vector2(-40, 20), Vector2(80, 60)), skin)

	# Head shifts sideways with displacement during the head turns.
	var head_x: float = 0.0
	if phase == Phase.TURN_LEFT:
		head_x = -displacement[LEFT]
	elif phase == Phase.TURN_RIGHT:
		head_x = displacement[RIGHT]
	draw_circle(center + Vector2(head_x, -40), 70.0, skin)

	# Force bars: doctor (blue) and patient (orange) per side; red when out of balance.
	for side in [LEFT, RIGHT]:
		var x: float = -420.0 if side == LEFT else 330.0
		var base := center + Vector2(x, 120)
		var bar_color := Color(0.3, 0.3, 0.3)
		if side in sides:
			var ok: bool = absf(displacement[side]) <= BALANCE_TOLERANCE
			bar_color = Color(0.3, 0.9, 0.3) if ok else Color(0.9, 0.3, 0.3)
		draw_rect(Rect2(base + Vector2(0, -200), Vector2(90, 200)), bar_color, false, 2.0)
		var doc_h: float = doctor_force[side] * 2.0
		var pat_h: float = effective_patient_force(side) * 2.0
		draw_rect(Rect2(base + Vector2(5, -doc_h), Vector2(35, doc_h)), Color(0.4, 0.6, 1.0))
		draw_rect(Rect2(base + Vector2(50, -pat_h), Vector2(35, pat_h)), Color(1.0, 0.6, 0.2))
