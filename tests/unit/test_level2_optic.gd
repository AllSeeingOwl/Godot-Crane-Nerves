extends GutTest

const DT: float = 1.0 / 60.0

var level: Level2Optic


func before_each() -> void:
	GameState.reset_state()
	level = load("res://scenes/levels/Level2_Optic.tscn").instantiate()
	add_child(level)
	level.set_process(false)
	level.shake_enabled = false


func after_each() -> void:
	if level:
		level.queue_free()
	GameState.reset_state()


## Puts both eyes exactly on the current target, at rest.
func _aim_both_at_target() -> void:
	for eye in [Level2Optic.LEFT, Level2Optic.RIGHT]:
		level.gaze[eye] = level.target_position()
		level.gaze_vel[eye] = Vector2.ZERO


func _hold_on_target(seconds: float) -> void:
	for i in range(int(seconds / DT)):
		if not level.is_active():
			return
		_aim_both_at_target()
		level.step(DT, Vector2.ZERO, Vector2.ZERO)


func test_initialization() -> void:
	assert_eq(level.level_id, 2, "Level ID should be 2")
	assert_eq(level.targets.size(), Level2Optic.CHART_ROWS.size(), "One target per chart row")
	for row in range(level.targets.size()):
		assert_eq(level.targets[row].x, row, "Targets go down the chart in order")
	assert_eq(level.current_target_index, 0, "Starts on the first letter")


func test_inputs_steer_each_eye_independently() -> void:
	var start_left: Vector2 = level.gaze[Level2Optic.LEFT]
	var start_right: Vector2 = level.gaze[Level2Optic.RIGHT]
	for i in range(30):
		level.step(DT, Vector2.UP, Vector2.ZERO)
	assert_lt(level.gaze[Level2Optic.LEFT].y, start_left.y - 20.0, "Left eye moved up")
	assert_almost_eq(level.gaze[Level2Optic.RIGHT].y, start_right.y, 0.5, "Right eye didn't")


func test_eyes_drift_outward_when_idle() -> void:
	var start_left: Vector2 = level.gaze[Level2Optic.LEFT]
	var start_right: Vector2 = level.gaze[Level2Optic.RIGHT]
	for i in range(60):
		level.step(DT, Vector2.ZERO, Vector2.ZERO)
	assert_lt(level.gaze[Level2Optic.LEFT].x, start_left.x, "Left eye drifts left")
	assert_gt(level.gaze[Level2Optic.RIGHT].x, start_right.x, "Right eye drifts right")


func test_holding_both_eyes_on_letter_reads_it() -> void:
	_hold_on_target(Level2Optic.READ_TIME + 0.1)
	assert_eq(level.current_target_index, 1, "Letter read after READ_TIME")
	assert_eq(GameState.stress, 0.0, "Reading cleanly causes no stress")


func test_one_eye_on_target_is_not_enough() -> void:
	for i in range(int(2.0 / DT)):
		level.gaze[Level2Optic.LEFT] = level.target_position()
		level.gaze[Level2Optic.RIGHT] = level.target_position() + Vector2(80, 0)
		level.gaze_vel[Level2Optic.LEFT] = Vector2.ZERO
		level.gaze_vel[Level2Optic.RIGHT] = Vector2.ZERO
		level.step(DT, Vector2.ZERO, Vector2.ZERO)
	assert_eq(level.current_target_index, 0, "Double vision: one eye alone can't read")


func test_smaller_letters_need_tighter_aim() -> void:
	var first_radius: float = level.read_radius()
	level.current_target_index = level.targets.size() - 1
	assert_lt(level.read_radius(), first_radius, "The bottom row is harder to read")


func test_reading_every_letter_wins() -> void:
	watch_signals(GameState)
	for i in range(level.targets.size()):
		_hold_on_target(Level2Optic.READ_TIME + 0.1)
	assert_eq(level.current_target_index, level.targets.size(), "Whole chart read")
	assert_signal_emitted(GameState, "level_won", "level_won should be emitted")


func test_cross_eyed_adds_stress() -> void:
	var center := Level2Optic.CHART_RECT.get_center()
	level.gaze[Level2Optic.LEFT] = center + Vector2(-150, 0)
	level.gaze[Level2Optic.RIGHT] = center + Vector2(150, 0)
	level.step(0.5, Vector2.ZERO, Vector2.ZERO)
	assert_gt(GameState.stress, 0.0, "Eyes far apart adds stress")


func test_rolling_eyes_off_chart_adds_stress_and_clamps() -> void:
	level.gaze[Level2Optic.LEFT] = Level2Optic.VIEW_RECT.position - Vector2(50, 50)
	level.step(DT, Vector2.ZERO, Vector2.ZERO)
	assert_gt(GameState.stress, 0.0, "Looking off the chart adds stress")
	assert_true(
		Level2Optic.VIEW_RECT.grow(0.01).has_point(level.gaze[Level2Optic.LEFT]),
		"Gaze is clamped back into view"
	)


func test_chart_shakes_when_enabled() -> void:
	level.shake_enabled = true
	level.step(0.7, Vector2.ZERO, Vector2.ZERO)
	assert_ne(level.chart_offset(), Vector2.ZERO, "The chart wobbles")


func test_target_queries_are_safe_after_the_chart_is_finished() -> void:
	level.current_target_index = level.targets.size()
	var last := level.targets[level.targets.size() - 1]
	assert_eq(
		level.target_position(), level.letter_position(last.x, last.y), "Falls back to last letter"
	)
	assert_gt(level.read_radius(), 0.0, "Radius is still defined")

