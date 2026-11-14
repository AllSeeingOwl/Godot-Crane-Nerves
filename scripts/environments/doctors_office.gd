extends Node3D

var mouse_x: float = 0.0
var mouse_y: float = 0.0

@onready var camera = $Camera3D


func _ready() -> void:
	if not camera:
		push_error("Camera3D not found!")


func _process(delta: float) -> void:
	if not camera:
		return

	var viewport = get_viewport()
	if viewport:
		var mouse_pos = viewport.get_mouse_position()
		var size = viewport.get_visible_rect().size

		# Normalize mouse to -1.0 to 1.0
		mouse_x = (mouse_pos.x / size.x) * 2.0 - 1.0
		mouse_y = (mouse_pos.y / size.y) * 2.0 - 1.0

		# Invert y because screen Y is down, but 3D Y is up
		mouse_y = -mouse_y

	# Smooth parallax
	var target_tx = 0.15 + mouse_x * 0.55
	var target_ty = 1.9 + mouse_y * 0.22  # + because we inverted y above

	# Simple lerp (assuming ~60fps)
	var lerp_factor = 1.0 - exp(-3.0 * delta)
	camera.position.x = lerp(camera.position.x, target_tx, lerp_factor)
	camera.position.y = lerp(camera.position.y, target_ty, lerp_factor)

	# Always look at the sitting patient's face area
	camera.look_at(Vector3(0.15, 1.75, 0))
