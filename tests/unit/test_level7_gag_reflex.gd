extends GutTest

var level: Level7GagReflex
var _level_manager: Node


func before_each() -> void:
	# Stop LevelManager reloading scenes when these tests win or lose the level.
	_level_manager = get_tree().root.get_node_or_null("LevelManager")
	if _level_manager:
		if GameState.game_over.is_connected(_level_manager._on_game_over):
			GameState.game_over.disconnect(_level_manager._on_game_over)
		if GameState.level_won.is_connected(_level_manager._on_level_won):
			GameState.level_won.disconnect(_level_manager._on_level_won)
	GameState.reset_stress()
	GameState.is_game_over = false
	level = Level7GagReflex.new()
	add_child(level)
	# Keep the mouth open and the hand steady unless a test says otherwise.
	level.set_process(false)
	level.mouth_timer = 1000.0
	level.tremor_offset = Vector2.ZERO


func after_each() -> void:
	if level:
		level.queue_free()
	GameState.is_game_over = false
	GameState.reset_stress()
	if _level_manager:
		if not GameState.game_over.is_connected(_level_manager._on_game_over):
			GameState.game_over.connect(_level_manager._on_game_over)
		if not GameState.level_won.is_connected(_level_manager._on_level_won):
			GameState.level_won.connect(_level_manager._on_level_won)


## Places the hand so the depressor tip sits at `tip`, aimed through the centre of the lips.
func _place_tip(tip: Vector2) -> void:
	var dir := tip.normalized()
	level.depressor_angle = dir.angle()
	level.hand_pos = tip - dir * Level7GagReflex.DEPRESSOR_LENGTH


## Moves the tip to `tip` and runs one simulation step with a matching previous position.
func _settle_tip_at(tip: Vector2, delta: float = 0.1) -> void:
	_place_tip(tip)
	level._prev_hand_pos = level.hand_pos
	level._prev_tip = level.get_tip_position()
	level.step(delta)


func test_initialization() -> void:
	assert_eq(level.level_id, 7, "Level ID should be 7")
	assert_eq(level.phase, Level7GagReflex.Phase.DEPRESS_TONGUE, "Starts in DEPRESS_TONGUE")
	assert_eq(level.mouth_state, Level7GagReflex.MouthState.OPEN, "Mouth starts open")
	assert_lt(level.get_tip_position().x, 0.0, "Depressor tip starts outside the mouth")


func test_holding_tongue_advances_phase() -> void:
	var tongue_point := Vector2(100, Level7GagReflex.TONGUE_Y + 5)
	_settle_tip_at(tongue_point, 0.5)
	assert_almost_eq(level.tongue_hold_progress, 0.5, 0.001, "Pressing the tongue builds progress")
	assert_eq(level.phase, Level7GagReflex.Phase.DEPRESS_TONGUE, "Not done after 0.5s")

	level.step(0.5)
	level.step(0.5)
	assert_eq(level.phase, Level7GagReflex.Phase.ELICIT_GAG, "Tongue held long enough moves on")
	assert_eq(GameState.stress, 0.0, "Gentle tongue press causes no stress")


func test_overpressing_tongue_adds_stress() -> void:
	var deep := Vector2(100, Level7GagReflex.TONGUE_Y + Level7GagReflex.TONGUE_PRESS_MAX + 5)
	_settle_tip_at(deep, 0.5)
	assert_gt(GameState.stress, 0.0, "Squashing the tongue adds stress")
	assert_eq(level.tongue_hold_progress, 0.0, "Overpressing does not count as holding")


func test_palate_tickle_adds_stress() -> void:
	_settle_tip_at(Vector2(100, Level7GagReflex.PALATE_Y - 5), 0.5)
	assert_gt(GameState.stress, 0.0, "Touching the palate adds stress")


func test_entering_outside_lip_gap_is_blocked() -> void:
	# Tip just outside the lips, angled steeply down so the shaft would cross below the gap.
	level.depressor_angle = deg_to_rad(45.0)
	level.hand_pos = Vector2(-150, 0)
	level._prev_hand_pos = level.hand_pos
	level._prev_tip = level.get_tip_position()
	assert_true(level._shaft_hits_lips(level.get_tip_position()), "Steep shaft hits the lip")

	level.step(0.016)
	assert_gt(GameState.stress, 0.0, "Jabbing the lips adds stress")
	assert_false(level._shaft_hits_lips(level.get_tip_position()), "Depressor is pushed back out")


func test_mouth_closing_on_depressor_chomps() -> void:
	_settle_tip_at(Vector2(100, 0))
	level.mouth_state = Level7GagReflex.MouthState.CLOSING
	level.mouth_gap = 1.0
	level.step(0.1)
	assert_gte(GameState.stress, Level7GagReflex.CHOMP_STRESS, "Getting chomped adds big stress")
	assert_eq(level.hand_pos, Level7GagReflex.HAND_START, "Depressor is knocked back out")


func test_mouth_cycle_closes_and_reopens() -> void:
	level.mouth_timer = 0.01
	level.update_mouth(0.02)
	assert_eq(
		level.mouth_state, Level7GagReflex.MouthState.WARNING, "Mouth twitches before closing"
	)
	level.update_mouth(Level7GagReflex.MOUTH_WARNING_TIME + 0.01)
	assert_eq(level.mouth_state, Level7GagReflex.MouthState.CLOSING, "Then starts closing")
	level.update_mouth(1.0)
	assert_eq(level.mouth_state, Level7GagReflex.MouthState.CLOSED, "Then is fully closed")
	assert_eq(level.mouth_gap, 0.0, "Closed mouth has no gap")
	level.update_mouth(Level7GagReflex.MOUTH_CLOSED_TIME + 0.01)
	level.update_mouth(10.0)
	assert_eq(level.mouth_state, Level7GagReflex.MouthState.OPEN, "Eventually reopens")
	assert_eq(level.mouth_gap, Level7GagReflex.MOUTH_OPEN_GAP, "Fully open again")


func test_touching_throat_before_tongue_adds_stress() -> void:
	_settle_tip_at(Vector2(Level7GagReflex.PHARYNX_X + 2, 0))
	assert_gt(GameState.stress, 0.0, "Touching the throat too early adds stress")
	assert_eq(level.phase, Level7GagReflex.Phase.DEPRESS_TONGUE, "Still in the first phase")


func test_rough_throat_touch_adds_stress() -> void:
	level.phase = Level7GagReflex.Phase.ELICIT_GAG
	_settle_tip_at(Vector2(150, 0))
	# Jump 80px into the throat in one frame: far faster than a gentle touch.
	_place_tip(Vector2(Level7GagReflex.PHARYNX_X + 5, 0))
	level.step(0.016)
	assert_gt(GameState.stress, 0.0, "Rough touch adds stress")
	assert_eq(level.phase, Level7GagReflex.Phase.ELICIT_GAG, "Rough touch does not win")


func test_gentle_throat_touch_wins() -> void:
	watch_signals(GameState)
	level.phase = Level7GagReflex.Phase.ELICIT_GAG
	_settle_tip_at(Vector2(Level7GagReflex.PHARYNX_X - 2, 0))
	_place_tip(Vector2(Level7GagReflex.PHARYNX_X + 2, 0))
	level.step(0.1)
	assert_eq(level.phase, Level7GagReflex.Phase.COMPLETED, "Gentle touch completes the exam")
	assert_signal_emitted(GameState, "level_won", "level_won should be emitted")


func test_overshooting_throat_makes_patient_vomit() -> void:
	watch_signals(GameState)
	level.phase = Level7GagReflex.Phase.ELICIT_GAG
	_settle_tip_at(Vector2(Level7GagReflex.PHARYNX_X + Level7GagReflex.GAG_OVERSHOOT + 5, 0))
	assert_eq(level.phase, Level7GagReflex.Phase.FAILED, "Pushing too far fails the level")
	assert_signal_emitted_with_parameters(GameState, "game_over", [Level7GagReflex.VOMIT_REASON])


func test_arm_stays_in_bounds() -> void:
	for i in range(200):
		level._apply_arm_input(Vector2.RIGHT, 0.05)
	assert_lte(level.hand_pos.x, Level7GagReflex.HAND_MAX.x, "Hand is clamped to its bounds")


func test_angle_is_clamped() -> void:
	for i in range(200):
		level._update_angle(level.hand_pos + Vector2(0, 500), 0.1)
	assert_almost_eq(level.depressor_angle, Level7GagReflex.MAX_ANGLE, 0.01, "Angle is clamped")
