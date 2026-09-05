extends GutTest


func before_each():
	GameState.reset_state()
	var lm = get_tree().root.get_node_or_null("LevelManager")
	if lm and GameState.game_over.is_connected(lm._on_game_over):
		GameState.game_over.disconnect(lm._on_game_over)


func after_each():
	GameState.reset_state()
	var lm = get_tree().root.get_node_or_null("LevelManager")
	if lm and not GameState.game_over.is_connected(lm._on_game_over):
		GameState.game_over.connect(lm._on_game_over)


func test_initialization():
	assert_eq(GameState.stress, 0.0, "Initial stress should be 0.0")
	assert_eq(GameState.current_level_id, 1, "Initial level should be 1")
	assert_eq(GameState.highest_unlocked_level, 1, "Initial highest unlocked level should be 1")
	assert_false(GameState.is_game_over, "Game over flag should initially be false")
	assert_eq(GameState.completed_levels.size(), 0, "Completed levels should initially be empty")


func test_add_stress():
	watch_signals(GameState)
	GameState.add_stress(10.0)
	assert_eq(GameState.stress, 10.0, "Stress should increase by 10.0")
	assert_signal_emitted_with_parameters(GameState, "stress_changed", [10.0, 10.0])


func test_add_stress_clamp():
	GameState.add_stress(150.0)
	assert_eq(GameState.stress, 100.0, "Stress should be clamped to 100.0")

	GameState.reset_stress()
	GameState.add_stress(50.0)
	GameState.add_stress(-100.0)
	assert_eq(GameState.stress, 0.0, "Stress should be clamped to 0.0")


func test_set_stress():
	GameState.set_stress(45.0)
	assert_eq(GameState.stress, 45.0, "Stress should be set to 45.0")


func test_reset_stress():
	GameState.add_stress(50.0)
	GameState.reset_stress()
	assert_eq(GameState.stress, 0.0, "Stress should be reset to 0.0")


func test_level_progression():
	GameState.set_current_level(2)
	assert_eq(GameState.current_level_id, 2, "Current level should be 2")
	assert_eq(GameState.highest_unlocked_level, 2, "Highest unlocked level should be 2")

	# Test clamping level range (1 to 4)
	GameState.set_current_level(0)
	assert_eq(GameState.current_level_id, 1, "Level ID clamped to MIN_LEVEL_ID (1)")

	GameState.set_current_level(10)
	assert_eq(GameState.current_level_id, 4, "Level ID clamped to MAX_LEVEL_ID (4)")

	GameState.set_current_level(2)
	var advanced = GameState.next_level()
	assert_true(advanced, "next_level() should return true when advancing")
	assert_eq(GameState.current_level_id, 3, "Current level should advance to 3")

	GameState.set_current_level(4)
	var advanced_beyond_max = GameState.next_level()
	assert_false(advanced_beyond_max, "next_level() should return false when at MAX_LEVEL_ID")
	assert_eq(GameState.current_level_id, 4, "Current level should remain at 4")


func test_level_win_condition():
	watch_signals(GameState)
	GameState.set_current_level(1)
	GameState.win_level()

	assert_signal_emitted_with_parameters(GameState, "level_completed", [1])
	assert_signal_emitted(GameState, "level_won")
	assert_true(GameState.completed_levels.has(1), "Level 1 should be marked as completed")
	assert_eq(GameState.highest_unlocked_level, 2, "Highest unlocked level should be 2")


func test_level_lose_condition():
	watch_signals(GameState)
	GameState.set_current_level(1)
	GameState.add_stress(100.0)

	assert_true(GameState.is_game_over, "Game over flag should be true after reaching max stress")
	assert_signal_emitted(GameState, "game_over")
	var params = get_signal_parameters(GameState, "game_over")
	assert_eq(
		params[0],
		"Patient got too stressed from the smells!",
		"Default level 1 failure reason correct"
	)


func test_custom_lose_condition():
	watch_signals(GameState)
	GameState.lose_level("Custom failure reason")
	assert_true(GameState.is_game_over, "is_game_over should be true")
	assert_signal_emitted_with_parameters(GameState, "game_over", ["Custom failure reason"])


func test_save_and_load_game_state():
	GameState.set_current_level(2)
	GameState.add_stress(35.0)
	GameState.win_level()

	GameState.save_game_state()

	GameState.reset_state()
	assert_eq(GameState.stress, 0.0, "Stress reset")
	assert_eq(GameState.current_level_id, 1, "Level reset")

	var loaded = GameState.load_game_state()
	assert_true(loaded, "load_game_state() should return true")
	assert_eq(GameState.stress, 35.0, "Saved stress should be restored")
	assert_eq(GameState.current_level_id, 2, "Saved level ID should be restored")
	assert_true(GameState.completed_levels.has(2), "Saved completed levels should be restored")


func test_reset_state():
	GameState.add_stress(75.0)
	GameState.set_current_level(3)
	GameState.win_level()
	GameState.is_game_over = true

	GameState.reset_state()

	assert_eq(GameState.stress, 0.0, "Stress reset to 0")
	assert_eq(GameState.current_level_id, 1, "Current level reset to 1")
	assert_eq(GameState.highest_unlocked_level, 1, "Highest unlocked level reset to 1")
	assert_false(GameState.is_game_over, "is_game_over reset to false")
	assert_eq(GameState.completed_levels.size(), 0, "completed_levels cleared")
