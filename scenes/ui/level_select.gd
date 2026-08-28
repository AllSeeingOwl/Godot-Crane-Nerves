extends Control

func _ready():
	$MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)

	# Connect level buttons
	var grid = $MarginContainer/VBoxContainer/GridContainer
	for child in grid.get_children():
		if child is Button:
			child.pressed.connect(_on_level_pressed.bind(child.name.to_int()))

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_level_pressed(level_id: int):
	# Just loading the Main scene for now, or you could do LevelManager.load_level(level_id)
	GameState.current_level_id = level_id
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
