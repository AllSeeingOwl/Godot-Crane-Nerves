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

func test_has_level():
	assert_true(_level_manager.has_level(1), "Level 1 should have a configured scene")
	assert_false(_level_manager.has_level(99), "Unknown levels should not have a scene")

func test_all_configured_level_scenes_exist():
	for level_id in _level_manager.LEVEL_SCENES:
		var path: String = _level_manager.LEVEL_SCENES[level_id]
		assert_true(ResourceLoader.exists(path), "Scene for level %d should exist: %s" % [level_id, path])

func test_load_level_clears_game_over():
	GameState.is_game_over = true
	GameState.stress = 80.0
	# Unknown level id so the test doesn't actually swap scenes.
	_level_manager.load_level(99)
	assert_false(GameState.is_game_over, "Loading a level should clear the game over flag")
	assert_eq(GameState.stress, 0.0, "Loading a level should reset stress")
