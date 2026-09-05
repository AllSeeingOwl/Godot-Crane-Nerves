class_name Level3EyeMovement
extends BaseLevel

## Level 3: Eye Movement Exam (H-Pattern Penlight Tracing)
## Mechanics:
## 1. Trace sequence of 6 nodes forming an H-pattern.
## 2. Penlight follows mouse with physics lag.
## 3. Node proximity (< 50px) advances progression in sequence.
## 4. Small ambient stress over time.
## 5. Win condition: all 6 nodes traced. Lose condition: stress >= 100.

const NODES: Array[Vector2] = [
	Vector2(0.3, 0.3),
	Vector2(0.3, 0.7),
	Vector2(0.3, 0.5),
	Vector2(0.7, 0.5),
	Vector2(0.7, 0.3),
	Vector2(0.7, 0.7)
]
const HIT_RADIUS_SQ: float = 2500.0  # 50px radius squared
const LAG_SPEED: float = 5.0
const AMBIENT_STRESS_CHANCE: float = 0.02
const AMBIENT_STRESS_AMOUNT: float = 0.5

var current_node_index: int = 0
var progress: float = 0.0
var penlight_pos: Vector2 = Vector2.ZERO

@onready var penlight_cursor: Control = (
	$PenlightCursor if has_node("PenlightCursor") else null
)
@onready var progress_bar: ProgressBar = (
	$UI/ProgressBox/ProgressBar if has_node("UI/ProgressBox/ProgressBar") else null
)
@onready var nodes_container: Control = (
	$NodesContainer if has_node("NodesContainer") else null
)


func _ready() -> void:
	level_id = 3
	level_title = "Level 3: Eye Movement"
	super._ready()

	penlight_pos = get_global_mouse_position()
	_setup_node_visuals()
	_update_ui()


func _setup_node_visuals() -> void:
	if not nodes_container:
		return

	for child in nodes_container.get_children():
		child.queue_free()

	for i in range(NODES.size()):
		var marker = Panel.new()
		marker.name = "NodeMarker_%d" % i
		marker.custom_minimum_size = Vector2(32, 32)
		marker.size = Vector2(32, 32)
		nodes_container.add_child(marker)


func _process(delta: float) -> void:
	if GameState.is_game_over or current_node_index >= NODES.size():
		return

	var viewport_size = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(1152, 648)

	# 1. Penlight physics lag movement
	var target_mouse_pos = get_global_mouse_position()
	var lerp_factor = clamp(1.0 - exp(-LAG_SPEED * delta), 0.0, 1.0)
	penlight_pos = penlight_pos.lerp(target_mouse_pos, lerp_factor)

	if penlight_cursor:
		penlight_cursor.position = penlight_pos

	# 2. Check distance to current node
	if current_node_index < NODES.size():
		var target_norm_pos = NODES[current_node_index]
		var target_screen_pos = Vector2(
			target_norm_pos.x * viewport_size.x,
			target_norm_pos.y * viewport_size.y
		)

		var dist_sq = penlight_pos.distance_squared_to(target_screen_pos)
		if dist_sq < HIT_RADIUS_SQ:
			current_node_index += 1
			progress = (float(current_node_index) / float(NODES.size())) * 100.0
			_update_ui()

			if current_node_index >= NODES.size():
				win_level()

	# 3. Ambient stress over time
	if randf() < AMBIENT_STRESS_CHANCE:
		GameState.add_stress(AMBIENT_STRESS_AMOUNT)

	_update_node_positions_and_visuals(viewport_size)


func _update_node_positions_and_visuals(viewport_size: Vector2) -> void:
	if not nodes_container:
		return

	var children = nodes_container.get_children()
	for i in range(children.size()):
		if i >= NODES.size():
			break
		var node_ctrl = children[i] as Control
		if not node_ctrl:
			continue

		var norm_pos = NODES[i]
		var target_pos = Vector2(
			norm_pos.x * viewport_size.x - 16.0,
			norm_pos.y * viewport_size.y - 16.0
		)
		node_ctrl.position = target_pos

		if i < current_node_index:
			node_ctrl.modulate = Color(0.2, 0.9, 0.3)  # Done (green)
		elif i == current_node_index:
			node_ctrl.modulate = Color(1.0, 0.9, 0.2)  # Current (yellow)
		else:
			node_ctrl.modulate = Color(0.5, 0.5, 0.5, 0.5)  # Upcoming (gray)


func _update_ui() -> void:
	if info_label:
		info_label.text = (
			"Level 3: Eye Movement\nNodes Traced: %d / %d"
			% [current_node_index, NODES.size()]
		)

	if controls_label:
		controls_label.text = "Controls: Move mouse to guide penlight and trace the H-pattern"

	if progress_bar:
		progress_bar.value = progress
