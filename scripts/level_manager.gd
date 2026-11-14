extends Node

const LEVEL_SCENES = {
	1: "res://scenes/levels/Level1_Olfactory.tscn",
	2: "res://scenes/levels/Level2_Optic.tscn",
	3: "res://scenes/levels/Level3_EyeMovement.tscn",
	4: "res://scenes/levels/Level4_Trigeminal.tscn",
	5: "res://scenes/levels/Level5_FacialNerve.tscn",
	6: "res://scenes/levels/Level6_Vestibulocochlear.tscn",
	7: "res://scenes/levels/Level7_GagReflex.tscn",
	8: "res://scenes/levels/Level8_Accessory.tscn",
	9: "res://scenes/levels/Level9_Hypoglossal.tscn",
}

const MAIN_MENU_SCENE = "res://scenes/ui/main_menu.tscn"

## When false, scene changes are skipped. The test suite turns this off so that
## winning or losing a level in a unit test doesn't replace the running test scene.
var scene_changes_enabled: bool = true


func _ready() -> void:
	if not GameState.level_won.is_connected(_on_level_won):
		GameState.level_won.connect(_on_level_won)
	if not GameState.game_over.is_connected(_on_game_over):
		GameState.game_over.connect(_on_game_over)


func _exit_tree() -> void:
	if GameState.level_won.is_connected(_on_level_won):
		GameState.level_won.disconnect(_on_level_won)
	if GameState.game_over.is_connected(_on_game_over):
		GameState.game_over.disconnect(_on_game_over)


func has_level(level_id: int) -> bool:
	return LEVEL_SCENES.has(level_id)


func load_level(level_id: int) -> void:
	GameState.current_level_id = level_id

	if LEVEL_SCENES.has(level_id):
		_change_scene(LEVEL_SCENES[level_id])
	else:
		print("No scene configured for level ", level_id)


func _on_level_won() -> void:
	print("Level won!")
	var next_level_id = GameState.current_level_id + 1
	if LEVEL_SCENES.has(next_level_id):
		load_level(next_level_id)
	else:
		print("You won the game!")
		GameState.reset_stress()
		_change_scene(MAIN_MENU_SCENE)


func _on_game_over(reason: String) -> void:
	print("Game Over: ", reason)
	GameState.reset_stress()
	load_level(GameState.current_level_id)


func _change_scene(path: String) -> void:
	if scene_changes_enabled and is_inside_tree():
		get_tree().call_deferred("change_scene_to_file", path)
