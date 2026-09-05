class_name Level4Trigeminal
extends BaseLevel

## Level 4: Trigeminal Nerve Exam (Facial Sensation - Sharp vs Soft)
## Mechanics:
## 1. Test 6 facial regions sequentially with sharp pin (Left Click) or soft cotton (Right Click).
## 2. Heavy tool cursor moves with extreme lag.
## 3. Hit target (< 60px) with correct tool advances level.
## 4. Wrong tool (+15 stress) or missing target area (+5 stress).
## 5. Win condition: all 6 regions correctly tested. Lose condition: stress >= 100.

const REGIONS: Array[Dictionary] = [
	{"x": 0.35, "y": 0.3, "type": "sharp", "label": "V1 (Ophthalmic) Left"},
	{"x": 0.65, "y": 0.3, "type": "soft", "label": "V1 (Ophthalmic) Right"},
	{"x": 0.35, "y": 0.5, "type": "soft", "label": "V2 (Maxillary) Left"},
	{"x": 0.65, "y": 0.5, "type": "sharp", "label": "V2 (Maxillary) Right"},
	{"x": 0.40, "y": 0.7, "type": "sharp", "label": "V3 (Mandibular) Left"},
	{"x": 0.60, "y": 0.7, "type": "soft", "label": "V3 (Mandibular) Right"}
]
const HIT_RADIUS_SQ: float = 3600.0  # 60px radius squared
const EXTREME_LAG_SPEED: float = 1.5
const WRONG_TOOL_STRESS: float = 15.0
const MISS_STRESS: float = 5.0

var current_region_index: int = 0
var feedback_text: String = ""
var progress: float = 0.0
var tool_pos: Vector2 = Vector2.ZERO

@onready var tool_cursor: Control = $ToolCursor if has_node("ToolCursor") else null
@onready var feedback_label: Label = $UI/FeedbackLabel if has_node("UI/FeedbackLabel") else null
@onready var target_label: Label = $UI/TargetLabel if has_node("UI/TargetLabel") else null
@onready var progress_bar: ProgressBar = (
	$UI/ProgressBox/ProgressBar if has_node("UI/ProgressBox/ProgressBar") else null
)
@onready var regions_container: Control = (
	$RegionsContainer if has_node("RegionsContainer") else null
)


func _ready() -> void:
	level_id = 4
	level_title = "Level 4: Trigeminal Nerve"
	super._ready()

	tool_pos = get_global_mouse_position()
	_setup_region_visuals()
	_update_ui()


func _setup_region_visuals() -> void:
	if not regions_container:
		return

	for child in regions_container.get_children():
		child.queue_free()

	for i in range(REGIONS.size()):
		var reg = REGIONS[i]
		var panel = Panel.new()
		panel.name = "Region_%d" % i
		panel.custom_minimum_size = Vector2(40, 40)
		panel.size = Vector2(40, 40)

		var lbl = Label.new()
		lbl.name = "TypeLabel"
		lbl.text = reg["type"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.anchors_preset = Control.PRESET_FULL_RECT
		panel.add_child(lbl)

		regions_container.add_child(panel)


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

	var viewport_size = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(1152, 648)

	var target_region = REGIONS[current_region_index]
	var target_screen_pos = Vector2(
		target_region["x"] * viewport_size.x,
		target_region["y"] * viewport_size.y
	)

	var dist_sq = tool_pos.distance_squared_to(target_screen_pos)
	if dist_sq < HIT_RADIUS_SQ:
		var is_correct = (
			(target_region["type"] == "sharp" and is_sharp)
			or (target_region["type"] == "soft" and not is_sharp)
		)

		if is_correct:
			feedback_text = "Correct! Patient felt " + target_region["type"]
			current_region_index += 1
			progress = (float(current_region_index) / float(REGIONS.size())) * 100.0
			_update_ui()

			if current_region_index >= REGIONS.size():
				win_level()
		else:
			feedback_text = "Wrong tool! Patient confused."
			GameState.add_stress(WRONG_TOOL_STRESS)
			_update_ui()
	else:
		feedback_text = "Missed the target area!"
		GameState.add_stress(MISS_STRESS)
		_update_ui()


func _process(delta: float) -> void:
	if GameState.is_game_over or current_region_index >= REGIONS.size():
		return

	var viewport_size = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(1152, 648)

	# Heavy tool lag
	var target_mouse_pos = get_global_mouse_position()
	var lerp_factor = clamp(1.0 - exp(-EXTREME_LAG_SPEED * delta), 0.0, 1.0)
	tool_pos = tool_pos.lerp(target_mouse_pos, lerp_factor)

	if tool_cursor:
		tool_cursor.position = tool_pos

	_update_region_positions_and_visuals(viewport_size)


func _update_region_positions_and_visuals(viewport_size: Vector2) -> void:
	if not regions_container:
		return

	var children = regions_container.get_children()
	for i in range(children.size()):
		if i >= REGIONS.size():
			break

		var reg_ctrl = children[i] as Control
		if not reg_ctrl:
			continue

		var reg_def = REGIONS[i]
		var target_pos = Vector2(
			reg_def["x"] * viewport_size.x - 20.0,
			reg_def["y"] * viewport_size.y - 20.0
		)
		reg_ctrl.position = target_pos

		if i < current_region_index:
			reg_ctrl.modulate = Color(0.2, 0.9, 0.3, 0.4)  # Tested (green)
			reg_ctrl.visible = true
		elif i == current_region_index:
			reg_ctrl.modulate = Color(1.0, 0.3, 0.3, 0.9)  # Active target (red)
			reg_ctrl.visible = true
		else:
			reg_ctrl.visible = false  # Hide future regions


func _update_ui() -> void:
	if info_label:
		info_label.text = (
			"Level 4: Trigeminal Nerve\nRegions Tested: %d / %d"
			% [current_region_index, REGIONS.size()]
		)

	if controls_label:
		controls_label.text = (
			"Controls: Left Click = Sharp Pin | Right Click = Soft Cotton"
		)

	if feedback_label:
		feedback_label.text = feedback_text

	if target_label:
		if current_region_index < REGIONS.size():
			var reg = REGIONS[current_region_index]
			target_label.text = "Target: %s (%s)" % [reg["label"], reg["type"]]
		else:
			target_label.text = "All regions tested!"

	if progress_bar:
		progress_bar.value = progress
