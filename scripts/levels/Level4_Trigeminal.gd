class_name Level4Trigeminal
extends BaseLevel

## Level 4: Trigeminal Nerve Exam (Facial Sensation - Sharp vs Soft)
## Mechanics:
## 1. Test the 3 trigeminal branches on both sides of the face (forehead V1, cheek V2, jaw V3)
##    with the sharp pin end (Left Click) or the soft cotton end (Right Click) of a neuro-tip.
## 2. The heavy tool follows the mouse with extreme lag.
## 3. Touching the target (< 60px) with the correct end advances.
## 4. Wrong end (+15 stress) or missing the target area (+5 stress); the patient reacts.
## 5. Win condition: all 6 regions correctly tested. Lose condition: stress >= 100.

const REGIONS: Array[Dictionary] = [
	{"feature": "forehead_l", "type": "sharp", "label": "V1 (Ophthalmic) Left"},
	{"feature": "forehead_r", "type": "soft", "label": "V1 (Ophthalmic) Right"},
	{"feature": "cheek_l", "type": "soft", "label": "V2 (Maxillary) Left"},
	{"feature": "cheek_r", "type": "sharp", "label": "V2 (Maxillary) Right"},
	{"feature": "jaw_l", "type": "sharp", "label": "V3 (Mandibular) Left"},
	{"feature": "jaw_r", "type": "soft", "label": "V3 (Mandibular) Right"}
]
const HIT_RADIUS_SQ: float = 3600.0  # 60px radius squared
const EXTREME_LAG_SPEED: float = 1.5
const WRONG_TOOL_STRESS: float = 15.0
const MISS_STRESS: float = 5.0

## Face placement as fractions of the play area (center) and of its height (scale).
const FACE_CENTER: Vector2 = Vector2(0.5, 0.57)
const FACE_SCALE: float = 0.24

const PIN_COLOR := Color(0.75, 0.78, 0.82)
const COTTON_COLOR := Color(0.98, 0.98, 0.96)
const SHARP_COLOR := Color(0.9, 0.25, 0.25)
const SOFT_COLOR := Color(0.35, 0.65, 0.95)

var current_region_index: int = 0
var feedback_text: String = ""
var progress: float = 0.0
var tool_pos: Vector2 = Vector2.ZERO

@onready var feedback_label: Label = $UI/FeedbackLabel if has_node("UI/FeedbackLabel") else null
@onready var target_label: Label = $UI/TargetLabel if has_node("UI/TargetLabel") else null
@onready var progress_bar: ProgressBar = (
	$UI/ProgressBox/ProgressBar if has_node("UI/ProgressBox/ProgressBar") else null
)


func _ready() -> void:
	level_id = 4
	level_title = "Level 4: Trigeminal Nerve"
	super._ready()

	tool_pos = get_global_mouse_position()
	_update_ui()


func face_center() -> Vector2:
	var size := get_play_area_size()
	return Vector2(size.x * FACE_CENTER.x, size.y * FACE_CENTER.y)


func face_scale() -> float:
	return get_play_area_size().y * FACE_SCALE


## Screen position of region `index`, on the drawn face.
func region_screen_pos(index: int) -> Vector2:
	return PatientKit.feature_point(face_center(), face_scale(), REGIONS[index]["feature"])


func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_game_over or current_region_index >= REGIONS.size():
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_interact(true)  # Sharp
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_interact(false)  # Soft


func _interact(is_sharp: bool) -> void:
	if current_region_index >= REGIONS.size():
		return

	var target_region: Dictionary = REGIONS[current_region_index]
	var dist_sq := tool_pos.distance_squared_to(region_screen_pos(current_region_index))
	if dist_sq < HIT_RADIUS_SQ:
		var is_correct: bool = (
			(target_region["type"] == "sharp" and is_sharp)
			or (target_region["type"] == "soft" and not is_sharp)
		)

		if is_correct:
			feedback_text = "Correct! Patient felt " + target_region["type"]
			if is_sharp:
				react({"eye_closed_l": 0.6, "eye_closed_r": 0.6, "smile_l": -0.5, "smile_r": -0.5})
			else:
				react({"smile_l": 0.6, "smile_r": 0.6})
			current_region_index += 1
			progress = (float(current_region_index) / float(REGIONS.size())) * 100.0
			_update_ui()

			if current_region_index >= REGIONS.size():
				win_level()
		else:
			feedback_text = "Wrong tool! Patient confused."
			react({"brow_raise": 1.0, "smile_l": -0.4, "smile_r": 0.4}, 0.8)
			GameState.add_stress(WRONG_TOOL_STRESS)
			_update_ui()
	else:
		feedback_text = "Missed the target area!"
		react({"eye_closed_l": 1.0, "eye_closed_r": 1.0, "brow_raise": -1.0}, 0.6)
		GameState.add_stress(MISS_STRESS)
		_update_ui()


func _process(delta: float) -> void:
	if GameState.is_game_over or current_region_index >= REGIONS.size():
		return

	# Heavy tool lag
	var target_mouse_pos := get_global_mouse_position()
	var lerp_factor := clampf(1.0 - exp(-EXTREME_LAG_SPEED * delta), 0.0, 1.0)
	tool_pos = tool_pos.lerp(target_mouse_pos, lerp_factor)
	queue_redraw()


func _update_ui() -> void:
	if info_label:
		info_label.text = (
			"Level 4: Trigeminal Nerve\nRegions Tested: %d / %d"
			% [current_region_index, REGIONS.size()]
		)

	if controls_label:
		controls_label.text = "Controls: Left Click = Sharp Pin | Right Click = Soft Cotton"

	if feedback_label:
		feedback_label.text = feedback_text

	if target_label:
		if current_region_index < REGIONS.size():
			var reg: Dictionary = REGIONS[current_region_index]
			target_label.text = "Target: %s (%s)" % [reg["label"], reg["type"]]
		else:
			target_label.text = "All regions tested!"

	if progress_bar:
		progress_bar.value = progress


func _draw() -> void:
	draw_backdrop()
	var center := face_center()
	var scale := face_scale()

	# The patient nervously watches the tool.
	var look := (tool_pos - center) / maxf(scale * 2.0, 1.0)
	look = look.limit_length(1.0)
	PatientKit.draw_patient(self, center, scale, patient_face({"look_l": look, "look_r": look}))

	# Tested regions get a tick, the current one a pulsing ring in its tool's colour.
	for i in range(REGIONS.size()):
		var pos := region_screen_pos(i)
		if i < current_region_index:
			draw_circle(pos, 9.0, Color(0.2, 0.75, 0.3, 0.8))
		elif i == current_region_index:
			var is_sharp: bool = REGIONS[i]["type"] == "sharp"
			var color := SHARP_COLOR if is_sharp else SOFT_COLOR
			var pulse := 1.0 + 0.12 * sin(Time.get_ticks_msec() / 150.0)
			draw_arc(pos, 30.0 * pulse, 0.0, TAU, 32, color, 3.0)
			draw_arc(pos, 60.0, 0.0, TAU, 48, Color(color, 0.25), 1.5)

	draw_hud_bands(168.0, 92.0)
	_draw_neuro_tip(tool_pos)


## A neuro-tip: pin at the business end, cotton at the other, held at an angle.
func _draw_neuro_tip(tip: Vector2) -> void:
	var dir := Vector2(1, 1.4).normalized()
	var butt := tip + dir * 90.0
	draw_line(tip, butt, Color(0.95, 0.9, 0.55), 7.0)
	draw_line(tip, tip + dir * 14.0, PIN_COLOR, 3.0)
	draw_circle(tip, 2.5, PIN_COLOR)
	draw_circle(butt + dir * 8.0, 11.0, COTTON_COLOR)
	draw_arc(butt + dir * 8.0, 11.0, 0.0, TAU, 20, Color(0.7, 0.7, 0.68), 1.5)
