class_name Level6Vestibulocochlear
extends BaseLevel

## Level 6: Vestibulocochlear Nerve Exam (Tuning Fork Test)
## Mechanics:
## Phase 1 (Strike): Time SPACE bar to strike tuning fork within target power range (70-90%).
## Phase 2 (Placement): Guide floaty tuning fork (Arrow keys/WASD)
## to requested target on patient's head.
## Press SPACE or ENTER to place fork on target.
## Vibration power decays over time. If vibration reaches 0, fork must be re-struck.
## Complete 3 placements (Weber: Top of Head, Rinne Left: Left Ear, Rinne Right: Right Ear) to win.

enum State { STRIKE, PLACE, COMPLETED }

const TARGET_POWER_MIN: float = 70.0
const TARGET_POWER_MAX: float = 90.0
const TOO_HARD_STRESS: float = 20.0
const TOO_SOFT_STRESS: float = 5.0
const MISSED_PLACEMENT_STRESS: float = 12.0

const POWER_SPEED: float = 120.0
const VIBRATION_DECAY_RATE: float = 15.0
const FLOAT_ACCEL: float = 400.0
const FLOAT_FRICTION: float = 3.0
const TARGET_TOLERANCE: float = 40.0

## Patient's head centre on screen and its PatientKit scale. Fork and target positions are
## relative to HEAD_ORIGIN, and the targets sit on the drawn head (top and both ears).
const HEAD_ORIGIN: Vector2 = Vector2(576, 380)
const HEAD_SCALE: float = 112.0
const FORK_START: Vector2 = Vector2(-240, 110)
const FORK_COLOR := Color(0.78, 0.8, 0.84)
const WAVE_COLOR := Color(1.0, 0.95, 0.5, 0.6)

const TARGET_LOCATIONS: Array[Dictionary] = [
	{
		"name": "Top of Head (Weber Test)",
		"position": Vector2(0, -140),
		"description": "Place tuning fork on top of the head"
	},
	{
		"name": "Left Mastoid / Ear (Rinne Test Left)",
		"position": Vector2(-116, 0),
		"description": "Place tuning fork near left ear"
	},
	{
		"name": "Right Mastoid / Ear (Rinne Test Right)",
		"position": Vector2(116, 0),
		"description": "Place tuning fork near right ear"
	}
]

var state: State = State.STRIKE
var current_target_index: int = 0

var power_meter: float = 0.0
var power_direction: float = 1.0

var vibration_power: float = 0.0

var fork_pos: Vector2 = FORK_START
var fork_vel: Vector2 = Vector2.ZERO

var feedback_text: String = ""

@onready var feedback_label: Label = $UI/FeedbackLabel if has_node("UI/FeedbackLabel") else null
@onready var target_label: Label = $UI/TargetLabel if has_node("UI/TargetLabel") else null
@onready var state_label: Label = $UI/StateLabel if has_node("UI/StateLabel") else null
@onready
var power_bar: ProgressBar = $UI/PowerBox/PowerBar if has_node("UI/PowerBox/PowerBar") else null
@onready var vibration_bar: ProgressBar = (
	$UI/VibrationBox/VibrationBar if has_node("UI/VibrationBox/VibrationBar") else null
)


func _ready() -> void:
	level_id = 6
	level_title = "Level 6: Vestibulocochlear Nerve"
	super._ready()
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_game_over or state == State.COMPLETED:
		return

	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var key_event := event as InputEventKey
	if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
		if state == State.STRIKE:
			strike_fork()
		elif state == State.PLACE:
			place_fork()


func _process(delta: float) -> void:
	if GameState.is_game_over or state == State.COMPLETED:
		return

	if state == State.STRIKE:
		_process_strike_phase(delta)
	elif state == State.PLACE:
		_process_place_phase(delta)

	_update_ui()


func _process_strike_phase(delta: float) -> void:
	power_meter += power_direction * POWER_SPEED * delta
	if power_meter >= 100.0:
		power_meter = 100.0
		power_direction = -1.0
	elif power_meter <= 0.0:
		power_meter = 0.0
		power_direction = 1.0


func _process_place_phase(delta: float) -> void:
	vibration_power -= VIBRATION_DECAY_RATE * delta
	if vibration_power <= 0.0:
		vibration_power = 0.0
		state = State.STRIKE
		feedback_text = "Vibration faded! Strike the tuning fork again."
		return

	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()

	fork_vel += input_dir * FLOAT_ACCEL * delta
	fork_vel = fork_vel.lerp(Vector2.ZERO, FLOAT_FRICTION * delta)
	fork_pos += fork_vel * delta


func strike_fork() -> void:
	if power_meter < TARGET_POWER_MIN:
		feedback_text = "Struck too softly! Barely a whisper."
		GameState.add_stress(TOO_SOFT_STRESS)
	elif power_meter > TARGET_POWER_MAX:
		feedback_text = "Struck too hard! EAR DAMAGE! *BOINK*"
		react({"eye_closed_l": 1.0, "eye_closed_r": 1.0, "jaw_open": 0.5}, 0.8)
		GameState.add_stress(TOO_HARD_STRESS)
	else:
		vibration_power = 100.0
		state = State.PLACE
		feedback_text = "Perfect strike! Now place the tuning fork on the target."

	power_meter = 0.0
	power_direction = 1.0


func place_fork() -> void:
	if current_target_index >= TARGET_LOCATIONS.size():
		return

	var target_info: Dictionary = TARGET_LOCATIONS[current_target_index]
	var target_pos: Vector2 = target_info["position"]

	var dist := fork_pos.distance_to(target_pos)
	if dist <= TARGET_TOLERANCE:
		feedback_text = "Success! %s complete." % target_info["name"]
		current_target_index += 1
		fork_pos = FORK_START
		fork_vel = Vector2.ZERO
		react({"smile_l": 0.7, "smile_r": 0.7}, 0.6)
		vibration_power = 0.0

		if current_target_index >= TARGET_LOCATIONS.size():
			state = State.COMPLETED
			win_level()
		else:
			state = State.STRIKE
	else:
		feedback_text = "Missed the target spot! Patient looks irritated."
		react({"brow_raise": -1.0, "smile_l": -0.5, "smile_r": -0.5}, 0.7)
		GameState.add_stress(MISSED_PLACEMENT_STRESS)


func _update_ui() -> void:
	if info_label:
		info_label.text = (
			"Level 6: Vestibulocochlear\nPlacements: %d / %d"
			% [current_target_index, TARGET_LOCATIONS.size()]
		)

	if state_label:
		if state == State.STRIKE:
			state_label.text = "PHASE: STRIKE FORK (Press SPACE at 70-90% Power)"
		elif state == State.PLACE:
			state_label.text = "PHASE: PLACE FORK (Arrows/WASD to float, SPACE to place)"
		else:
			state_label.text = "EXAM COMPLETE"

	if target_label:
		if current_target_index < TARGET_LOCATIONS.size():
			var info: Dictionary = TARGET_LOCATIONS[current_target_index]
			target_label.text = "Target: %s (%s)" % [info["name"], info["description"]]
		else:
			target_label.text = "All placements finished!"

	if feedback_label:
		feedback_label.text = feedback_text

	if power_bar:
		power_bar.value = power_meter

	if vibration_bar:
		vibration_bar.value = vibration_power

	queue_redraw()


func _draw() -> void:
	draw_backdrop()

	var to_fork := fork_pos.limit_length(HEAD_SCALE * 2.0) / (HEAD_SCALE * 2.0)
	var face := {"look_l": to_fork, "look_r": to_fork}
	if state == State.PLACE and _fork_near_target():
		face["eye_closed_l"] = 0.5
		face["eye_closed_r"] = 0.5
		face["smile_l"] = 0.3
		face["smile_r"] = 0.3
	PatientKit.draw_patient(self, HEAD_ORIGIN, HEAD_SCALE, patient_face(face))

	if current_target_index < TARGET_LOCATIONS.size():
		var target: Vector2 = HEAD_ORIGIN + TARGET_LOCATIONS[current_target_index]["position"]
		var pulse := 1.0 + 0.15 * sin(Time.get_ticks_msec() / 160.0)
		draw_arc(target, TARGET_TOLERANCE * pulse, 0.0, TAU, 40, Color(0.4, 1.0, 0.4, 0.9), 3.0)

	_draw_tuning_fork(HEAD_ORIGIN + fork_pos)

	draw_hud_bands(196.0, 0.0)
	# Backing panels for the side meters
	for x in [30.0, 1052.0]:
		draw_rect(Rect2(Vector2(x, 214), Vector2(70, 220)), Color(0.06, 0.08, 0.07, 0.72))


func _fork_near_target() -> bool:
	if current_target_index >= TARGET_LOCATIONS.size():
		return false
	var target: Vector2 = TARGET_LOCATIONS[current_target_index]["position"]
	return fork_pos.distance_to(target) <= TARGET_TOLERANCE


## A tuning fork standing on its foot at `foot`; the prongs shake while it vibrates.
func _draw_tuning_fork(foot: Vector2) -> void:
	var shake := sin(Time.get_ticks_msec() / 12.0) * vibration_power * 0.04
	var yoke := foot + Vector2(0, -38)
	draw_line(foot, yoke, FORK_COLOR, 6.0)
	draw_circle(foot, 5.0, FORK_COLOR)
	draw_line(yoke + Vector2(-11, 0), yoke + Vector2(11, 0), FORK_COLOR, 6.0)
	for side in [-1.0, 1.0]:
		var base: Vector2 = yoke + Vector2(side * 11.0, 0)
		draw_line(base, base + Vector2(side * shake, -70), FORK_COLOR, 6.0)

	if vibration_power > 0.0:
		var alpha := vibration_power / 100.0
		var center := yoke + Vector2(0, -40)
		for i in range(3):
			var radius := 26.0 + i * 12.0 + fmod(Time.get_ticks_msec() / 40.0, 12.0)
			var color := Color(WAVE_COLOR, WAVE_COLOR.a * alpha * (1.0 - i * 0.3))
			draw_arc(center, radius, -0.6, 0.6, 12, color, 2.0)
			draw_arc(center, radius, PI - 0.6, PI + 0.6, 12, color, 2.0)
