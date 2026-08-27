extends GutTest

func before_each():
	GameState.reset_stress()
	GameState.current_level_id = 1

func after_each():
	GameState.reset_stress()

func test_initialization():
	assert_eq(GameState.stress, 0.0, "Initial stress should be 0.0")

func test_add_stress():
	GameState.add_stress(10.0)
	assert_eq(GameState.stress, 10.0, "Stress should increase by 10.0")

func test_add_stress_clamp():
	GameState.add_stress(150.0)
	assert_eq(GameState.stress, 100.0, "Stress should be clamped to 100.0")

func test_game_over_signal():
	watch_signals(GameState)
	GameState.add_stress(100.0)
	assert_signal_emitted(GameState, 'game_over')
	var parameters = get_signal_parameters(GameState, 'game_over')
	assert_eq(parameters[0], "Patient got too stressed from the smells!", "Reason correct")

func test_reset_stress():
	GameState.add_stress(50.0)
	GameState.reset_stress()
	assert_eq(GameState.stress, 0.0, "Stress should be reset to 0.0")
