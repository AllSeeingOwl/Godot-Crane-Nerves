extends GutTest

var _ui_instance: UIManager = null


func before_each() -> void:
	GameState.reset_state()
	var lm = get_tree().root.get_node_or_null("LevelManager")
	if lm:
		if GameState.game_over.is_connected(lm._on_game_over):
			GameState.game_over.disconnect(lm._on_game_over)
		if GameState.level_won.is_connected(lm._on_level_won):
			GameState.level_won.disconnect(lm._on_level_won)

	var ui_scene = load("res://scenes/ui/UI.tscn")
	_ui_instance = ui_scene.instantiate()
	add_child(_ui_instance)


func after_each() -> void:
	if _ui_instance and is_instance_valid(_ui_instance):
		_ui_instance.queue_free()
		_ui_instance = null

	GameState.reset_state()
	var lm = get_tree().root.get_node_or_null("LevelManager")
	if lm:
		if not GameState.game_over.is_connected(lm._on_game_over):
			GameState.game_over.connect(lm._on_game_over)
		if not GameState.level_won.is_connected(lm._on_level_won):
			GameState.level_won.connect(lm._on_level_won)


func test_ui_initialization() -> void:
	assert_not_null(_ui_instance, "UI instance should be loaded")
	assert_not_null(_ui_instance.stress_bar, "Stress bar node should exist")
	assert_not_null(_ui_instance.stress_value_label, "Stress value label should exist")
	assert_not_null(_ui_instance.level_indicator_label, "Level indicator label should exist")
	assert_not_null(_ui_instance.objective_text_label, "Objective text label should exist")
	assert_false(_ui_instance.win_screen.visible, "Win screen should be hidden initially")
	assert_false(_ui_instance.lose_screen.visible, "Lose screen should be hidden initially")


func test_realtime_stress_updates() -> void:
	assert_eq(_ui_instance.stress_bar.value, 0.0, "Initial stress bar value should be 0.0")

	GameState.add_stress(35.5)
	assert_eq(_ui_instance.stress_bar.value, 35.5, "Stress bar should update to 35.5")
	assert_true(
		_ui_instance.stress_value_label.text.contains("35.5"),
		"Numeric label should display stress value"
	)

	GameState.add_stress(10.0)
	assert_eq(_ui_instance.stress_bar.value, 45.5, "Stress bar should update to 45.5")


func test_level_display_and_objectives() -> void:
	_ui_instance.update_level_display(1)
	assert_true(
		_ui_instance.level_indicator_label.text.contains("Olfactory"),
		"Level 1 title should contain Olfactory"
	)

	_ui_instance.update_level_display(2)
	assert_true(
		_ui_instance.level_indicator_label.text.contains("Optic"),
		"Level 2 title should contain Optic"
	)

	_ui_instance.set_objective("Custom objective text")
	assert_eq(
		_ui_instance.objective_text_label.text,
		"Custom objective text",
		"Objective text should match custom objective"
	)


func test_win_screen_on_level_completed() -> void:
	assert_false(_ui_instance.win_screen.visible, "Win screen starts hidden")
	GameState.win_level()
	assert_true(_ui_instance.win_screen.visible, "Win screen should be visible on level win")


func test_lose_screen_on_game_over() -> void:
	assert_false(_ui_instance.lose_screen.visible, "Lose screen starts hidden")
	GameState.lose_level("Test loss reason")
	assert_true(_ui_instance.lose_screen.visible, "Lose screen should be visible on game over")
	assert_eq(
		_ui_instance.lose_reason_label.text,
		"Test loss reason",
		"Lose screen reason label should match error message"
	)


func test_fade_out_and_fade_in() -> void:
	watch_signals(_ui_instance)
	_ui_instance.fade_out(0.01)
	await _ui_instance.transition_finished
	assert_signal_emitted(_ui_instance, "transition_finished")
	assert_eq(
		_ui_instance.transition_overlay.color.a,
		1.0,
		"Transition overlay alpha should be 1.0 after fade_out"
	)

	_ui_instance.fade_in(0.01)
	await _ui_instance.transition_finished
	assert_eq(
		_ui_instance.transition_overlay.color.a,
		0.0,
		"Transition overlay alpha should be 0.0 after fade_in"
	)


func test_button_signals() -> void:
	watch_signals(_ui_instance)
	_ui_instance._on_win_restart_pressed()
	assert_signal_emitted(_ui_instance, "restart_requested")

	_ui_instance._on_win_next_pressed()
	assert_signal_emitted(_ui_instance, "next_level_requested")
