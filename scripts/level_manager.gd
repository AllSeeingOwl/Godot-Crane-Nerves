extends Node

const LEVEL_SCENES = {
	1: "res://scenes/levels/level_1_olfactory.tscn",
	# Assuming other levels will be added here
}

func _ready():
	GameState.level_won.connect(_on_level_won)
	GameState.game_over.connect(_on_game_over)

	# Typically, loading initial level could be done here,
	# but typically main menu is used instead. Let's keep it manual
	# for now or let the main menu call load_level(1).

func load_level(level_id: int):
	GameState.current_level_id = level_id

	if LEVEL_SCENES.has(level_id):
		get_tree().call_deferred("change_scene_to_file", LEVEL_SCENES[level_id])
	else:
		print("No scene configured for level ", level_id)

func _on_level_won():
	print("Level won!")
	var next_level_id = GameState.current_level_id + 1
	if LEVEL_SCENES.has(next_level_id):
		load_level(next_level_id)
	else:
		print("You won the game!")
		# Game won logic

func _on_game_over(reason: String):
	print("Game Over: ", reason)
	# Here we would typically show a game over screen and then retry
	# For now, we will reset the level and stress
	GameState.reset_stress()
	load_level(GameState.current_level_id)
