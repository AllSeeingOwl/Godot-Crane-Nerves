extends GutTest

const DT: float = 1.0 / 60.0

var level: Level9Hypoglossal


func before_each() -> void:
	GameState.reset_stress()
	GameState.is_game_over = false
	level = Level9Hypoglossal.new()
	add_child(level)
	level.set_process(false)
	# No deviation unless a test asks for it.
	level.deviation_dir = 0.0


func after_each() -> void:
	if level:
		level.queue_free()
	GameState.is_game_over = false
	GameState.reset_stress()


## Steers the tongue toward `target` for `seconds` of simulated time.
func _aim(target: Vector2, seconds: float) -> void:
	for i in range(int(seconds / DT)):
		level.step(DT, target)


func _target_pos(index: int) -> Vector2:
	return Level9Hypoglossal.TARGETS[index]["position"]


func test_initialization() -> void:
	var fresh := Level9Hypoglossal.new()
	add_child(fresh)
	assert_eq(fresh.level_id, 9, "Level ID should be 9")
	assert_eq(fresh.phase, Level9Hypoglossal.Phase.EXAMINING, "Starts examining")
	assert_eq(fresh.current_target_index, 0, "Starts on the first target")
	assert_eq(absf(fresh.deviation_dir), 1.0, "Tongue deviates to one side")
	assert_eq(fresh.segment_pos.size(), Level9Hypoglossal.SEGMENT_COUNT, "Has tongue segments")
	fresh.free()


func test_tip_follows_target() -> void:
	_aim(Vector2(0, 100), 3.0)
	assert_lt(level.tip_pos.distance_to(Vector2(0, 100)), 5.0, "Tip settles on the target")


func test_holding_still_on_target_advances() -> void:
	_aim(_target_pos(0), 3.0)
	assert_eq(level.current_target_index, 1, "Holding the first target moves to the next")
	assert_eq(GameState.stress, 0.0, "A clean, gentle hold causes no stress")


func test_moving_through_target_does_not_count() -> void:
	level.tip_pos = _target_pos(0)
	level.tip_vel = Vector2(400, 0)
	level.step(DT, _target_pos(0))
	assert_eq(level.hold_progress, 0.0, "A fast-moving tip doesn't count as holding")


func test_full_exam_wins() -> void:
	watch_signals(GameState)
	for i in range(Level9Hypoglossal.TARGETS.size()):
		_aim(_target_pos(i), 3.0)
	assert_eq(level.phase, Level9Hypoglossal.Phase.COMPLETED, "All targets complete the exam")
	assert_signal_emitted(GameState, "level_won", "level_won should be emitted")


func test_deviation_pulls_tongue_sideways() -> void:
	level.deviation_dir = 1.0
	_aim(Vector2(0, 100), 3.0)
	assert_gt(level.tip_pos.x, Level9Hypoglossal.TARGET_RADIUS, "Tip drifts right off the aim")


func test_deviation_blocks_target_unless_corrected() -> void:
	level.deviation_dir = 1.0
	_aim(_target_pos(0), 3.0)
	assert_eq(level.current_target_index, 0, "Aiming straight at the target misses it")

	var drift := Level9Hypoglossal.DEVIATION_FORCE / Level9Hypoglossal.TIP_STIFFNESS
	_aim(_target_pos(0) - Vector2(drift, 0), 3.0)
	assert_eq(level.current_target_index, 1, "Aiming against the drift hits it")


func test_overstretching_adds_stress() -> void:
	_aim(Vector2(0, 600), 1.0)
	assert_gt(GameState.stress, 0.0, "Pulling the tongue too far adds stress")
	assert_true(
		level.tip_pos.distance_to(Level9Hypoglossal.ROOT) <= Level9Hypoglossal.MAX_REACH + 0.01,
		"The tongue can't stretch past MAX_REACH"
	)


func test_whipping_adds_stress() -> void:
	level.tip_pos = Vector2(0, 60)
	level.tip_vel = Vector2(2000, 0)
	level.step(DT, Vector2(0, 60))
	assert_true(GameState.stress >= Level9Hypoglossal.WHIP_STRESS, "Whipping flings spit")


func test_curling_back_gurgles() -> void:
	var spot := Vector2(0, Level9Hypoglossal.GURGLE_Y - 10)
	level.tip_pos = spot
	level.step(DT, spot)
	assert_gt(GameState.stress, 0.0, "Curling the tongue back makes the patient gurgle")
	assert_eq(level.phase, Level9Hypoglossal.Phase.EXAMINING, "Gurgling is not a fail yet")


func test_swallowing_tongue_fails() -> void:
	watch_signals(GameState)
	_aim(Vector2(0, -150), 3.0)
	assert_eq(level.phase, Level9Hypoglossal.Phase.FAILED, "Swallowing the tongue fails")
	assert_signal_emitted_with_parameters(
		GameState, "game_over", [Level9Hypoglossal.SWALLOW_REASON]
	)
