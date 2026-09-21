extends GutTest

var Level5Script = preload("res://scripts/levels/Level5_FacialNerve.gd")
var _level_instance = null


func before_each():
	GameState.reset_state()
	_level_instance = Level5Script.new()
	add_child_autofree(_level_instance)


func test_initialization():
	assert_eq(_level_instance.level_id, 5, "Level ID should be 5")
	assert_eq(
		_level_instance.current_expression_index,
		0,
		"Should start at first expression index 0"
	)
	assert_eq(_level_instance.muscle_states.size(), 10, "Should have 10 muscle groups")
	for state in _level_instance.muscle_states:
		assert_false(state, "All muscle states should default to false")


func test_toggle_muscle():
	_level_instance.toggle_muscle(0)
	assert_true(_level_instance.muscle_states[0], "Muscle 0 should be toggled to true")

	_level_instance.toggle_muscle(0)
	assert_false(_level_instance.muscle_states[0], "Muscle 0 should be toggled back to false")


func test_submit_correct_expression():
	# Target 0: Smile requires muscles 6 & 7
	_level_instance.toggle_muscle(6)
	_level_instance.toggle_muscle(7)

	_level_instance.submit_expression()

	assert_eq(
		_level_instance.current_expression_index,
		1,
		"Expression index should advance to 1"
	)
	assert_gt(_level_instance.progress, 0.0, "Progress should increase")
	for state in _level_instance.muscle_states:
		assert_false(
			state,
			"Muscle states should be reset after successful expression submission"
		)


func test_submit_incorrect_expression():
	# Submit without toggling required muscles
	var initial_stress = GameState.stress
	_level_instance.submit_expression()

	assert_eq(
		_level_instance.current_expression_index,
		0,
		"Expression index should not advance on wrong submission"
	)
	assert_gt(
		GameState.stress,
		initial_stress,
		"Stress should increase on wrong submission"
	)


func test_level_completion():
	var total_expressions = _level_instance.TARGET_EXPRESSIONS.size()

	for i in range(total_expressions):
		var target = _level_instance.TARGET_EXPRESSIONS[i]
		_level_instance._reset_muscle_states()

		for req in target.get("required", []):
			_level_instance.muscle_states[req] = true

		for forb in target.get("forbidden", []):
			_level_instance.muscle_states[forb] = false

		_level_instance.submit_expression()

	assert_eq(
		_level_instance.current_expression_index,
		total_expressions,
		"All expressions should be completed"
	)
	assert_eq(_level_instance.progress, 100.0, "Progress should be 100%")
