extends Node3D

func _ready():
	# Load HUD dynamically
	var hud_scene = load("res://scenes/ui/hud.tscn")
	if hud_scene:
		var hud_instance = hud_scene.instantiate()
		add_child(hud_instance)
