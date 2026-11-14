extends GutTest

var level: Level8Accessory


func before_each() -> void:
	GameState.reset_stress()
	GameState.is_game_over = false
	level = Level8Accessory.new()
	add_child(level)
	level.set_process(false)
	# No random twitches unless a test asks for one.
	level.twitch_timer = 1000.0


func after_each() -> void:
	if level:
		level.queue_free()
	GameState.is_game_over = false
	GameState.reset_stress()


func _set_forces(doctor: Array, patient: Array) -> void:
	for side in [Level8Accessory.LEFT, Level8Accessory.RIGHT]:
		level.doctor_force[side] = doctor[side]
		level.patient_force[side] = patient[side]
		level.displacement[side] = patient[side] - doctor[side]


func test_initialization() -> void:
	assert_eq(level.level_id, 8, "Level ID should be 8")
	assert_eq(level.phase, Level8Accessory.Phase.SHRUG, "Starts with the shoulder shrug")
	assert_eq(level.active_sides().size(), 2, "Shrug uses both sides")


func test_inputs_ramp_up_and_down() -> void:
	level.apply_inputs([true, false], [false, true], 0.5)
	assert_almost_eq(
		level.doctor_force[0], Level8Accessory.PRESS_RATE * 0.5, 0.001, "Doctor L ramps"
	)
	assert_eq(level.doctor_force[1], 0.0, "Doctor R stays at 0")
	assert_almost_eq(
		level.patient_force[1], Level8Accessory.PRESS_RATE * 0.5, 0.001, "Patient R ramps"
	)

	level.apply_inputs([false, false], [false, false], 10.0)
	assert_eq(level.doctor_force[0], 0.0, "Released force decays to 0")
	assert_eq(level.patient_force[1], 0.0, "Released force decays to 0")


func test_balanced_hold_advances_to_head_turn() -> void:
	_set_forces([60.0, 60.0], [60.0, 60.0])
	level.step(1.0)
	level.step(1.0)
	assert_eq(level.phase, Level8Accessory.Phase.SHRUG, "Not done before HOLD_TIME")
	level.step(1.0)
	assert_eq(level.phase, Level8Accessory.Phase.TURN_LEFT, "Balanced hold passes the shrug")
	assert_eq(level.doctor_force[0], 0.0, "Forces reset for the next part")
	assert_eq(GameState.stress, 0.0, "A clean hold causes no stress")


func test_weak_doctor_force_does_not_count() -> void:
	_set_forces([20.0, 20.0], [20.0, 20.0])
	level.step(1.0)
	assert_eq(level.hold_progress, 0.0, "Balanced but too gentle does not test anything")


func test_overpowering_adds_stress() -> void:
	_set_forces([100.0, 100.0], [60.0, 60.0])
	level.step(0.1)
	assert_gt(GameState.stress, 0.0, "Crushing the shoulders adds stress")
	assert_eq(level.hold_progress, 0.0, "No progress while overpowering")


func test_patient_overshoot_adds_stress() -> void:
	_set_forces([50.0, 50.0], [100.0, 100.0])
	level.step(0.1)
	assert_gt(GameState.stress, 0.0, "Shoulders shooting up adds stress")


func test_unbalanced_pressure_adds_stress() -> void:
	_set_forces([90.0, 45.0], [90.0, 45.0])
	level.step(0.1)
	assert_gt(GameState.stress, 0.0, "Pressing unevenly adds stress")
	assert_eq(level.hold_progress, 0.0, "No progress with unbalanced pressure")


func test_catastrophic_overpower_fails_level() -> void:
	watch_signals(GameState)
	_set_forces([100.0, 100.0], [0.0, 0.0])
	level.step(0.1)
	assert_eq(level.phase, Level8Accessory.Phase.FAILED, "Dislocating the shoulder fails")
	assert_signal_emitted(GameState, "game_over", "game_over should be emitted")


func test_head_turn_only_checks_its_side() -> void:
	level.phase = Level8Accessory.Phase.TURN_LEFT
	# Right side idle (0 doctor force) must not block the left-turn test.
	_set_forces([60.0, 0.0], [60.0, 0.0])
	level.step(1.0)
	assert_almost_eq(level.hold_progress, 1.0, 0.001, "Only the left side counts")


func test_full_exam_wins() -> void:
	watch_signals(GameState)
	for phase_side in [-1, Level8Accessory.LEFT, Level8Accessory.RIGHT]:
		if phase_side == -1:
			_set_forces([60.0, 60.0], [60.0, 60.0])
		elif phase_side == Level8Accessory.LEFT:
			_set_forces([60.0, 0.0], [60.0, 0.0])
		else:
			_set_forces([0.0, 60.0], [0.0, 60.0])
		for i in range(3):
			level.step(1.0)
	assert_eq(level.phase, Level8Accessory.Phase.COMPLETED, "All three parts complete the exam")
	assert_signal_emitted(GameState, "level_won", "level_won should be emitted")


func test_twitch_kicks_patient_force() -> void:
	level.twitch_timer = 0.0
	level.step(0.01)
	var total: float = absf(level.twitch[0]) + absf(level.twitch[1])
	assert_gt(total, 0.0, "A twitch adds force to one side")
	assert_gt(level.twitch_timer, 0.0, "Next twitch is scheduled")
