extends GutTest

var _level_manager

func before_each():
	GameState.current_level_id = 1
	_level_manager = load("res://scripts/level_manager.gd").new()
	add_child(_level_manager)

func after_each():
	_level_manager.queue_free()

func test_load_level():
	_level_manager.load_level(1)
	assert_eq(GameState.current_level_id, 1, "Should correctly update GameState current_level_id")
