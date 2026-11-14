class_name Level9Hypoglossal
extends BaseLevel

## Level 9: Hypoglossal Nerve (XII) - Tongue Movement Exam
## Front-on view of the patient's open mouth (local origin = centre of the mouth, +y is down/out).
## Mechanics:
## - The tongue tip chases the mouse on a soft spring: laggy, wobbly and prone to overshoot.
##   The rest of the tongue is a chain of springy segments that flop along behind it.
## - The patient's tongue deviates toward one (random) side, as with real XII palsy.
## - Hit TARGETS in order (out, left, right, left, right) by holding the tip still
##   (speed <= MAX_HOLD_SPEED) inside TARGET_RADIUS for HOLD_TIME seconds.
## - Stretching past MAX_REACH or whipping the tongue around adds stress.
## - Curling the tongue back into the throat makes the patient gurgle (stress);
##   too far and they swallow it (instant loss).

enum Phase { EXAMINING, COMPLETED, FAILED }

const HEAD_ORIGIN: Vector2 = Vector2(576, 330)
const ROOT: Vector2 = Vector2(0, -20)
const SEGMENT_COUNT: int = 8

const TARGETS: Array[Dictionary] = [
	{"name": "Stick it OUT", "position": Vector2(0, 120)},
	{"name": "Touch the LEFT corner", "position": Vector2(-110, 20)},
	{"name": "Touch the RIGHT corner", "position": Vector2(110, 20)},
	{"name": "LEFT again", "position": Vector2(-110, 20)},
	{"name": "RIGHT again", "position": Vector2(110, 20)},
]
const TARGET_RADIUS: float = 25.0
const HOLD_TIME: float = 0.6
const MAX_HOLD_SPEED: float = 150.0

# --- Tongue physics ---
const TIP_STIFFNESS: float = 40.0
const TIP_DAMPING: float = 4.0
const SEGMENT_STIFFNESS: float = 120.0
const SEGMENT_DAMPING: float = 8.0
const SAG: float = 12.0
const MAX_REACH: float = 160.0
const DEVIATION_FORCE: float = 1400.0  # ~35px steady drift against TIP_STIFFNESS

# --- Hazards ---
const OVERSTRETCH_STRESS_PER_SEC: float = 15.0
const WHIP_SPEED: float = 1000.0
const WHIP_STRESS: float = 5.0
const WHIP_COOLDOWN: float = 0.5
const GURGLE_Y: float = -45.0
const GURGLE_STRESS_PER_SEC: float = 20.0
const SWALLOW_Y: float = -90.0
const SWALLOW_REASON: String = "The patient swallowed their own tongue! Somehow."

var phase: Phase = Phase.EXAMINING
var current_target_index: int = 0
var hold_progress: float = 0.0
var feedback_text: String = ""

## -1 = tongue drifts left, 1 = drifts right, 0 = no deviation.
var deviation_dir: float = 0.0

var tip_pos: Vector2 = ROOT + Vector2(0, 40)
var tip_vel: Vector2 = Vector2.ZERO
var segment_pos: Array[Vector2] = []
var segment_vel: Array[Vector2] = []

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _whip_cooldown: float = 0.0

@onready var target_label: Label = $UI/TargetLabel if has_node("UI/TargetLabel") else null
@onready var feedback_label: Label = $UI/FeedbackLabel if has_node("UI/FeedbackLabel") else null
@onready var hold_bar: ProgressBar = $UI/HoldBox/HoldBar if has_node("UI/HoldBox/HoldBar") else null


func _ready() -> void:
	level_id = 9
	level_title = "Level 9: Hypoglossal Nerve"
	rng.randomize()
	deviation_dir = -1.0 if rng.randf() < 0.5 else 1.0
	feedback_text = (
		"This patient's tongue drifts to the %s." % ("LEFT" if deviation_dir < 0.0 else "RIGHT")
	)
	_reset_segments()
	super._ready()
	_update_ui()


func _process(delta: float) -> void:
	if not is_active():
		return

	step(delta, get_global_mouse_position() - HEAD_ORIGIN)
	_update_ui()
	queue_redraw()


func is_active() -> bool:
	return not GameState.is_game_over and phase == Phase.EXAMINING


## Advances the tongue one tick toward `target` (mouth-local) and applies the exam rules.
func step(delta: float, target: Vector2) -> void:
	if not is_active() or delta <= 0.0:
		return

	_whip_cooldown = maxf(_whip_cooldown - delta, 0.0)

	var overstretched := target.distance_to(ROOT) > MAX_REACH
	_move_tip(delta, target)
	_move_segments(delta)

	if tip_pos.y < SWALLOW_Y:
		_fail(SWALLOW_REASON)
		return

	if tip_pos.y < GURGLE_Y:
		feedback_text = "*Gurgle* Too far back! The patient is choking."
		GameState.add_stress(GURGLE_STRESS_PER_SEC * delta)
	elif overstretched:
		feedback_text = "The tongue doesn't go that far!"
		GameState.add_stress(OVERSTRETCH_STRESS_PER_SEC * delta)

	if tip_vel.length() > WHIP_SPEED and _whip_cooldown <= 0.0:
		feedback_text = "*Splat* Spit flies across the room."
		GameState.add_stress(WHIP_STRESS)
		_whip_cooldown = WHIP_COOLDOWN

	if is_active():
		_check_target(delta)


func _move_tip(delta: float, target: Vector2) -> void:
	var accel := (target - tip_pos) * TIP_STIFFNESS + Vector2(deviation_dir * DEVIATION_FORCE, 0)
	tip_vel += accel * delta
	tip_vel = tip_vel.lerp(Vector2.ZERO, clampf(TIP_DAMPING * delta, 0.0, 1.0))
	tip_pos += tip_vel * delta

	# The tongue can only stretch so far from its root.
	var offset := tip_pos - ROOT
	if offset.length() > MAX_REACH:
		tip_pos = ROOT + offset.normalized() * MAX_REACH
		tip_vel = tip_vel.slide(offset.normalized())


func _move_segments(delta: float) -> void:
	var damping := clampf(SEGMENT_DAMPING * delta, 0.0, 1.0)
	for i in range(SEGMENT_COUNT):
		var t := float(i + 1) / float(SEGMENT_COUNT + 1)
		var rest := ROOT.lerp(tip_pos, t) + Vector2(0, sin(t * PI) * SAG)
		segment_vel[i] += (rest - segment_pos[i]) * SEGMENT_STIFFNESS * delta
		segment_vel[i] = segment_vel[i].lerp(Vector2.ZERO, damping)
		segment_pos[i] += segment_vel[i] * delta


func _check_target(delta: float) -> void:
	var target_info: Dictionary = TARGETS[current_target_index]
	var target_pos: Vector2 = target_info["position"]
	var on_target := tip_pos.distance_to(target_pos) <= TARGET_RADIUS
	var steady := tip_vel.length() <= MAX_HOLD_SPEED

	if on_target and steady:
		hold_progress = minf(hold_progress + delta, HOLD_TIME)
		if hold_progress >= HOLD_TIME:
			_advance_target()
	else:
		hold_progress = 0.0


func _advance_target() -> void:
	hold_progress = 0.0
	current_target_index += 1
	if current_target_index >= TARGETS.size():
		phase = Phase.COMPLETED
		feedback_text = "Strong, symmetrical and slimy. Cranial nerve XII checks out!"
		win_level()
	else:
		feedback_text = "Good! Next: %s" % TARGETS[current_target_index]["name"]


func _fail(reason: String) -> void:
	phase = Phase.FAILED
	feedback_text = reason
	lose_level(reason)


func _reset_segments() -> void:
	segment_pos.clear()
	segment_vel.clear()
	for i in range(SEGMENT_COUNT):
		var t := float(i + 1) / float(SEGMENT_COUNT + 1)
		segment_pos.append(ROOT.lerp(tip_pos, t))
		segment_vel.append(Vector2.ZERO)


func _update_ui() -> void:
	if info_label:
		info_label.text = (
			"Level 9: Hypoglossal Nerve (XII)\nTargets: %d / %d"
			% [current_target_index, TARGETS.size()]
		)

	if target_label:
		if current_target_index < TARGETS.size():
			target_label.text = "Target: %s" % TARGETS[current_target_index]["name"]
		else:
			target_label.text = "All targets done!"

	if feedback_label:
		feedback_label.text = feedback_text

	if hold_bar:
		hold_bar.value = hold_progress / HOLD_TIME * 100.0


func _draw() -> void:
	draw_backdrop()
	var o := HEAD_ORIGIN
	var stress_t := clampf(GameState.stress / 100.0, 0.0, 1.0)
	var skin := PatientKit.SKIN.lerp(PatientKit.FLUSH, stress_t * 0.35)

	# Close-up of the face: gown, ears, face, hair
	var gown := PackedVector2Array(
		[
			o + Vector2(-420, 330),
			o + Vector2(-330, 230),
			o + Vector2(330, 230),
			o + Vector2(420, 330)
		]
	)
	draw_colored_polygon(gown, PatientKit.GOWN)
	for side in [-1.0, 1.0]:
		PatientKit.draw_ellipse(self, o + Vector2(side * 238.0, -20), Vector2(32, 60), skin, 2.0)
	PatientKit.draw_ellipse(self, o + Vector2(0, -30), Vector2(240, 265), skin, 3.0)
	var hair := PackedVector2Array()
	for i in range(17):
		var a := PI + PI * float(i) / 16.0
		hair.append(o + Vector2(0, -30) + Vector2(cos(a) * 245.0, sin(a) * 270.0))
	hair.append(o + Vector2(150, -215))
	hair.append(o + Vector2(-150, -215))
	draw_colored_polygon(hair, PatientKit.HAIR)

	# Eyes watch the tongue tip (and squeeze when the patient gurgles)
	var squint := 0.5 if tip_pos.y < GURGLE_Y else 0.0
	for side in [-1.0, 1.0]:
		var eye_pos := o + Vector2(side * 85.0, -128)
		var look := ((o + tip_pos) - eye_pos) / 250.0
		draw_line(
			eye_pos + Vector2(-side * 30.0, -38),
			eye_pos + Vector2(side * 30.0, -42),
			PatientKit.HAIR,
			10.0
		)
		PatientKit.draw_eye(self, eye_pos, 170.0, look.limit_length(1.0), squint, skin)
	var nose := PackedVector2Array(
		[
			o + Vector2(-8, -128),
			o + Vector2(-34, -78),
			o + Vector2(0, -68),
			o + Vector2(34, -78),
			o + Vector2(8, -128)
		]
	)
	draw_colored_polygon(nose, PatientKit.SKIN_SHADE)
	for side in [-1.0, 1.0]:
		PatientKit.draw_ellipse(
			self, o + Vector2(side * 165.0, -40), Vector2(40, 26), Color(PatientKit.FLUSH, 0.25)
		)

	# Wide-open mouth: lips, teeth, dark cavity and the gurgle line at the back
	var mouth := Rect2(o + Vector2(-130, -50), Vector2(260, 110))
	draw_rect(mouth.grow(12), PatientKit.LIP)
	draw_rect(mouth, PatientKit.MOUTH_DARK)
	draw_rect(Rect2(o + Vector2(-110, -50), Vector2(220, 14)), PatientKit.TEETH)
	draw_rect(Rect2(o + Vector2(-100, 46), Vector2(200, 14)), PatientKit.TEETH)
	draw_line(o + Vector2(-130, GURGLE_Y), o + Vector2(130, GURGLE_Y), Color(1, 0.3, 0.3, 0.4), 2.0)

	# Current target
	if current_target_index < TARGETS.size():
		var target_pos: Vector2 = TARGETS[current_target_index]["position"]
		var pulse := 1.0 + 0.12 * sin(Time.get_ticks_msec() / 150.0)
		draw_arc(o + target_pos, TARGET_RADIUS * pulse, 0.0, TAU, 32, Color(0.4, 1, 0.4), 3.0)

	# Tongue: thick at the root, thinner toward the tip, with a centre groove
	var points: Array[Vector2] = [ROOT]
	points.append_array(segment_pos)
	points.append(tip_pos)
	var tongue_color := Color(0.9, 0.45, 0.52)
	for i in range(points.size() - 1):
		var width := lerpf(34.0, 16.0, float(i) / float(points.size() - 1))
		draw_line(o + points[i], o + points[i + 1], tongue_color, width)
		draw_circle(o + points[i + 1], width * 0.5, tongue_color)
	draw_circle(o + ROOT, 17.0, tongue_color)
	for i in range(points.size() - 2):
		draw_line(o + points[i], o + points[i + 1], Color(0.75, 0.3, 0.38), 2.0)

	draw_hud_bands(145.0, 0.0)
	draw_rect(Rect2(Vector2(30, 214), Vector2(80, 220)), Color(0.06, 0.08, 0.07, 0.72))
