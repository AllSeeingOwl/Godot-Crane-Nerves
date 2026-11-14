extends GutTest

const DT: float = 1.0 / 60.0

var level: Level3EyeMovement


func before_each() -> void:
	GameState.reset_state()
	level = load("res://scenes/levels/Level3_EyeMovement.tscn").instantiate()
	add_child(level)
	level.set_process(false)


func after_each() -> void:
	if level:
		level.queue_free()
	GameState.reset_state()


func test_initialization() -> void:
	assert_eq(level.level_id, 3, "Level ID should be 3")
	assert_eq(level.current_node_index, 0, "Starts on the first point")
	assert_eq(level.NODES.size(), 6, "H-pattern has 6 points")
	var tip := level.tip_position()
	assert_true(Rect2(0, 0, 1152, 648).has_point(tip), "Penlight starts on screen")


func test_every_h_point_is_reachable() -> void:
	for i in range(level.NODES.size()):
		assert_true(level.reach_toward(level.node_position(i)), "Point %d is in reach" % i)
		assert_lt(level.tip_position().distance_to(level.node_position(i)), 1.0, "IK lands on it")
		assert_between(level.shoulder_angle, level.SHOULDER_MIN, level.SHOULDER_MAX)
		assert_between(level.elbow_angle, level.ELBOW_MIN, level.ELBOW_MAX)


func test_h_points_are_clear_of_the_eyes() -> void:
	for i in range(level.NODES.size()):
		for eye in level.eye_positions():
			assert_gt(
				level.node_position(i).distance_to(eye),
				level.NEAR_EYE_RADIUS + level.HIT_RADIUS,
				"Point %d can be traced without going near an eye" % i
			)


func test_shoulder_and_elbow_inputs_move_the_joints() -> void:
	var shoulder_before := level.shoulder_angle
	var elbow_before := level.elbow_angle
	for i in range(20):
		level.step(DT, 1.0, -1.0)
	assert_gt(level.shoulder_angle, shoulder_before, "W swings the shoulder")
	assert_lt(level.elbow_angle, elbow_before, "O bends the elbow")


func test_arm_sags_under_gravity() -> void:
	var before := level.shoulder_angle
	for i in range(60):
		level.step(DT, 0.0, 0.0)
	assert_ne(level.shoulder_angle, before, "An idle arm doesn't hold still")


func test_joints_are_clamped() -> void:
	level.elbow_vel = 50.0
	level.step(DT, 0.0, 0.0)
	assert_true(level.elbow_angle <= level.ELBOW_MAX, "Elbow can't hyperextend")
	level.elbow_vel = -50.0
	level.step(DT, 0.0, 0.0)
	assert_true(level.elbow_angle >= level.ELBOW_MIN, "Elbow can't over-bend")


func test_points_must_be_traced_in_order() -> void:
	level.reach_toward(level.node_position(2))
	level.check_current_node()
	assert_eq(level.current_node_index, 0, "Skipping ahead doesn't count")
	level.reach_toward(level.node_position(0))
	level.check_current_node()
	assert_eq(level.current_node_index, 1, "The first point counts")


func test_tracing_the_whole_h_wins() -> void:
	watch_signals(GameState)
	for i in range(level.NODES.size()):
		level.reach_toward(level.node_position(i))
		level.check_current_node()
	assert_eq(level.phase, Level3EyeMovement.Phase.COMPLETED, "H traced")
	assert_signal_emitted(GameState, "level_won", "level_won should be emitted")


func test_near_the_eye_adds_stress() -> void:
	var eye: Vector2 = level.eye_positions()[0]
	level.reach_toward(eye + Vector2(0, 35))
	level.step(DT, 0.0, 0.0)
	assert_gt(GameState.stress, 0.0, "Shining the light too close adds stress")
	assert_eq(level.phase, Level3EyeMovement.Phase.TRACING, "Close is not a fail yet")


func test_poking_the_eye_fails() -> void:
	watch_signals(GameState)
	level.reach_toward(level.eye_positions()[1])
	level.step(DT, 0.0, 0.0)
	assert_eq(level.phase, Level3EyeMovement.Phase.FAILED, "Poking an eye fails the level")
	assert_signal_emitted_with_parameters(GameState, "game_over", [level.POKE_REASON])


func test_whipping_the_light_adds_stress() -> void:
	level.reach_toward(level.node_position(5))
	level.elbow_vel = -3.0
	level.step(DT, 0.0, 0.0)
	assert_gt(level.tip_speed, level.FAST_SPEED, "The tip is moving fast")
	assert_gt(GameState.stress, 0.0, "Moving too fast for the patient adds stress")
