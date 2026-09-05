extends Node

const LEVEL_SCENES = {
	1: "res://scenes/levels/Level1_Olfactory.tscn",
	2: "res://scenes/levels/Level2_Optic.tscn",
	3: "res://scenes/levels/Level3_EyeMovement.tscn",
	4: "res://scenes/levels/Level4_Trigeminal.tscn",
}


func _ready() -> void:
	GameState.level_won.connect(_on_level_won)
	GameState.game_over.connect(_on_game_over)


func load_level(level_id: int) -> void:
	GameState.current_level_id = level_id

	if LEVEL_SCENES.has(level_id):
		get_tree().call_deferred("change_scene_to_file", LEVEL_SCENES[level_id])
	else:
		print("No scene configured for level ", level_id)


func _on_level_won() -> void:
	print("Level won!")
	var next_level_id = GameState.current_level_id + 1
	if LEVEL_SCENES.has(next_level_id):
		load_level(next_level_id)
	else:
		print("You won the game!")


func _on_game_over(reason: String) -> void:
	print("Game Over: ", reason)
	GameState.reset_stress()
	load_level(GameState.current_level_id)
