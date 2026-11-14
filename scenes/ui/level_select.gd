extends Control


func _ready() -> void:
	$MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)

	# Connect level buttons; levels without a scene yet are shown but disabled.
	var grid = $MarginContainer/VBoxContainer/GridContainer
	for child in grid.get_children():
		if child is Button:
			var level_id: int = child.name.to_int()
			if LevelManager.has_level(level_id):
				child.pressed.connect(_on_level_pressed.bind(level_id))
			else:
				child.disabled = true
				child.tooltip_text = "Coming soon"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_level_pressed(level_id: int) -> void:
	LevelManager.load_level(level_id)
