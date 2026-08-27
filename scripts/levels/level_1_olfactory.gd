extends Node2D

const VIALS = {
	"coffee": {"name": "Coffee", "color": Color(0.6, 0.3, 0.0), "type": "good"},
	"mint": {"name": "Mint", "color": Color(0.2, 0.8, 0.4), "type": "good"},
	"surstromming": {"name": "Surströmming", "color": Color(0.8, 0.6, 0.0), "type": "bad"}
}

var selected_vial: String = ""
var identified_vials: Array = []
var nose_velocity: Vector2
var progress: float = 0.0

@onready var nose: Control = $Nose
@onready var nose_progress: ProgressBar = $Nose/ProgressBar
@onready var vial_cursor: Control = $VialCursor
@onready var vial_cursor_color: ColorRect = $VialCursor/ColorRect
@onready var info_label: Label = $UI/InfoLabel
@onready var stress_bar: ProgressBar = $UI/StressBar


func _ready():
	# Initial random velocity for the nose
	nose_velocity = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 200.0

	# Connect UI buttons
	$UI/VialsBox/CoffeeBtn.pressed.connect(_on_vial_pressed.bind("coffee"))
	$UI/VialsBox/MintBtn.pressed.connect(_on_vial_pressed.bind("mint"))
	$UI/VialsBox/SurstrommingBtn.pressed.connect(_on_vial_pressed.bind("surstromming"))

	GameState.stress_changed.connect(_on_stress_changed)
	_update_ui()


func _on_stress_changed(new_stress: float, _delta: float):
	stress_bar.value = new_stress


func _on_vial_pressed(vial_id: String):
	if identified_vials.has(vial_id):
		return

	if selected_vial == vial_id:
		selected_vial = ""  # Deselect
	else:
		selected_vial = vial_id

	_update_ui()


func _update_ui():
	# Update label
	info_label.text = "Level 1: Olfactory Nerve\nIdentified: %d / 2" % identified_vials.size()

	# Update buttons visual state
	for btn_id in ["coffee", "mint", "surstromming"]:
		var btn = $UI/VialsBox.get_node(btn_id.capitalize() + "Btn")
		if identified_vials.has(btn_id):
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)
		else:
			btn.disabled = false
			if selected_vial == btn_id:
				btn.modulate = Color(1.2, 1.2, 1.2)  # Highlight
			else:
				btn.modulate = Color(1.0, 1.0, 1.0)

	if selected_vial != "":
		vial_cursor.visible = true
		vial_cursor_color.color = VIALS[selected_vial].color
	else:
		vial_cursor.visible = false


func _process(delta: float):
	var mouse_pos = get_global_mouse_position()

	# 1. Update Nose Position (Wandering)
	var nose_speed_mult = 100.0
	nose.position += nose_velocity * delta * nose_speed_mult

	# Bounce off walls (margin 100)
	var screen_size = get_viewport_rect().size
	var margin = 100.0

	if nose.position.x < margin:
		nose.position.x = margin
		nose_velocity.x *= -1
	elif nose.position.x > screen_size.x - margin:
		nose.position.x = screen_size.x - margin
		nose_velocity.x *= -1

	if nose.position.y < margin:
		nose.position.y = margin
		nose_velocity.y *= -1
	elif nose.position.y > screen_size.y - margin:
		nose.position.y = screen_size.y - margin
		nose_velocity.y *= -1

	# Random direction changes
	if randf() < (0.02 * (delta / 0.0166)):
		nose_velocity.x += randf_range(-1.0, 1.0) * 2.0
		nose_velocity.y += randf_range(-1.0, 1.0) * 2.0

		# Limit speed
		var speed_sq = nose_velocity.length_squared()
		if speed_sq > 4.0:
			nose_velocity = nose_velocity.normalized() * 2.0

	# 2. Logic for Smelling
	if selected_vial != "":
		# Cursor override
		vial_cursor.position = mouse_pos

		var vial_def = VIALS[selected_vial]
		var dx = nose.position.x - mouse_pos.x
		var dy = nose.position.y - mouse_pos.y
		var dist_sq = dx * dx + dy * dy

		if not identified_vials.has(selected_vial):
			if vial_def.type == "bad":
				# Evade if bad smell
				if dist_sq < 90000:
					if dist_sq > 0:
						var inv_dist = 1.0 / sqrt(dist_sq)
						nose_velocity.x += dx * inv_dist * 0.5
						nose_velocity.y += dy * inv_dist * 0.5

					# Rapid stress increase
					if dist_sq < 22500:
						GameState.add_stress(12.0 * delta)

			if dist_sq < 10000:
				# Inside smelling range
				progress += delta * 50.0

				# Slowly increase stress just by taking time
				GameState.add_stress(1.2 * delta)

				if progress >= 100.0:
					identified_vials.append(selected_vial)
					selected_vial = ""
					progress = 0.0
					_update_ui()
					if identified_vials.size() >= 2:
						GameState.level_won.emit()
			else:
				# Decay progress
				if progress > 0:
					progress = max(0.0, progress - delta * 100.0)
	else:
		if progress > 0:
			progress = max(0.0, progress - delta * 100.0)

	# Update progress bar
	if progress > 0:
		nose_progress.visible = true
		nose_progress.value = progress
	else:
		nose_progress.visible = false
