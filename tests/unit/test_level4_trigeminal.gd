extends GutTest

var _level_instance = null
var _level_won_emitted: bool = false
var _game_over_emitted: bool = false


func before_each():
	GameState.reset_state()
	_level_won_emitted = false
	_game_over_emitted = false

	var lm = get_tree().root.get_node_or_null("LevelManager")
	if lm:
		if GameState.game_over.is_connected(lm._on_game_over):
			GameState.game_over.disconnect(lm._on_game_over)
		if GameState.level_won.is_connected(lm._on_level_won):
			GameState.level_won.disconnect(lm._on_level_won)

	if not GameState.level_won.is_connected(_on_test_level_won):
		GameState.level_won.connect(_on_test_level_won)
	if not GameState.game_over.is_connected(_on_test_game_over):
		GameState.game_over.connect(_on_test_game_over)

	var scene = load("res://scenes/levels/Level4_Trigeminal.tscn")
	_level_instance = scene.instantiate()
	add_child(_level_instance)


func after_each():
	if _level_instance:
		_level_instance.queue_free()
		_level_instance = null

	if GameState.level_won.is_connected(_on_test_level_won):
		GameState.level_won.disconnect(_on_test_level_won)
	if GameState.game_over.is_connected(_on_test_game_over):
		GameState.game_over.disconnect(_on_test_game_over)

	var lm = get_tree().root.get_node_or_null("LevelManager")
	if lm:
		if not GameState.game_over.is_connected(lm._on_game_over):
			GameState.game_over.connect(lm._on_game_over)
		if not GameState.level_won.is_connected(lm._on_level_won):
			GameState.level_won.connect(lm._on_level_won)

	GameState.reset_state()


func _on_test_level_won():
	_level_won_emitted = true


func _on_test_game_over(_reason: String):
	_game_over_emitted = true


func test_level4_instantiation():
	assert_not_null(_level_instance, "Level 4 instance should be created")
	assert_eq(_level_instance.current_region_index, 0, "Initial region index should be 0")
	assert_eq(_level_instance.progress, 0.0, "Initial progress should be 0.0")
	assert_eq(_level_instance.REGIONS.size(), 6, "Should have 6 facial regions")


func test_correct_tool_interaction():
	var viewport_size = Vector2(1000, 1000)

	# Region 0 is sharp at (0.35, 0.3)
	_level_instance.tool_pos = Vector2(0.35 * viewport_size.x, 0.3 * viewport_size.y)
	_level_instance._interact(true)  # Sharp tool

	assert_eq(_level_instance.current_region_index, 1, "Correct tool advances region")
	assert_true(
		_level_instance.feedback_text.begins_with("Correct"),
		"Feedback indicates correct"
	)


func test_wrong_tool_interaction():
	var viewport_size = Vector2(1000, 1000)

	# Region 0 is sharp at (0.35, 0.3)
	_level_instance.tool_pos = Vector2(0.35 * viewport_size.x, 0.3 * viewport_size.y)
	var initial_stress = GameState.stress
	_level_instance._interact(false)  # Soft tool (wrong)

	assert_eq(_level_instance.current_region_index, 0, "Wrong tool does not advance region")
	assert_true(GameState.stress > initial_stress, "Wrong tool adds stress")
	assert_eq(
		_level_instance.feedback_text,
		"Wrong tool! Patient confused.",
		"Feedback indicates wrong tool"
	)


func test_miss_target_area():
	_level_instance.tool_pos = Vector2(0, 0)
	var initial_stress = GameState.stress
	_level_instance._interact(true)

	assert_eq(_level_instance.current_region_index, 0, "Miss does not advance region")
	assert_true(GameState.stress > initial_stress, "Miss adds stress")
	assert_eq(
		_level_instance.feedback_text,
		"Missed the target area!",
		"Feedback indicates miss"
	)


func test_win_condition_all_regions_tested():
	var viewport_size = Vector2(1000, 1000)

	for i in range(_level_instance.REGIONS.size()):
		var reg = _level_instance.REGIONS[i]
		_level_instance.tool_pos = Vector2(
			reg["x"] * viewport_size.x,
			reg["y"] * viewport_size.y
		)
		var is_sharp = (reg["type"] == "sharp")
		_level_instance._interact(is_sharp)

	assert_eq(_level_instance.current_region_index, 6, "All 6 regions tested")
	assert_true(_level_won_emitted, "level_won signal should be emitted")
