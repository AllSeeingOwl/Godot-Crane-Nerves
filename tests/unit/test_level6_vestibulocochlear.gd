extends GutTest

const GutUtils = preload("res://addons/gut/utils.gd")

var level: Level6Vestibulocochlear


func before_each() -> void:
	GameState.reset_stress()
	level = Level6Vestibulocochlear.new()
	add_child(level)


func after_each() -> void:
	if level:
		level.queue_free()


func test_initialization() -> void:
	assert_eq(level.level_id, 6, "Level ID should be 6")
	assert_eq(level.state, Level6Vestibulocochlear.State.STRIKE, "Initial state should be STRIKE")
	assert_eq(level.current_target_index, 0, "Initial target index should be 0")
	assert_eq(level.vibration_power, 0.0, "Initial vibration power should be 0")


func test_soft_strike_adds_stress() -> void:
	level.power_meter = 30.0
	var initial_stress = GameState.stress
	level.strike_fork()
	assert_gt(GameState.stress, initial_stress, "Soft strike should increase stress")
	assert_eq(level.state, Level6Vestibulocochlear.State.STRIKE, "State should remain STRIKE")


func test_hard_strike_adds_stress() -> void:
	level.power_meter = 95.0
	var initial_stress = GameState.stress
	level.strike_fork()
	assert_gt(GameState.stress, initial_stress, "Hard strike should increase stress")
	assert_eq(level.state, Level6Vestibulocochlear.State.STRIKE, "State should remain STRIKE")


func test_perfect_strike_transitions_to_place() -> void:
	level.power_meter = 80.0
	level.strike_fork()
	assert_eq(level.state, Level6Vestibulocochlear.State.PLACE, "Perfect strike transitions to PLACE")
	assert_eq(level.vibration_power, 100.0, "Vibration power set to 100")


func test_placement_miss_adds_stress() -> void:
	level.state = Level6Vestibulocochlear.State.PLACE
	level.vibration_power = 100.0
	level.fork_pos = Vector2(500.0, 500.0) # Far from target
	var initial_stress = GameState.stress
	level.place_fork()
	assert_gt(GameState.stress, initial_stress, "Missed placement should increase stress")
	assert_eq(level.current_target_index, 0, "Target index should not advance on miss")


func test_successful_placements_win_level() -> void:
	var win_signaled = false
	var signal_callback = func(): win_signaled = true
	GameState.level_won.connect(signal_callback)

	for i in range(Level6Vestibulocochlear.TARGET_LOCATIONS.size()):
		level.state = Level6Vestibulocochlear.State.PLACE
		level.vibration_power = 100.0
		var target_pos = Level6Vestibulocochlear.TARGET_LOCATIONS[i]["position"]
		level.fork_pos = target_pos
		level.place_fork()

	assert_true(win_signaled, "level_won signal should be emitted after all placements complete")
	assert_eq(level.state, Level6Vestibulocochlear.State.COMPLETED, "State should be COMPLETED")

	GameState.level_won.disconnect(signal_callback)
