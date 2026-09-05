extends GutTest

var _level_instance = null
var _level_won_emitted: bool = false
var _game_over_emitted: bool = false


func before_each():
	GameState.reset_state()
	_level_won_emitted = false
	_game_over_emitted = false

	var lm = get_tree().root.get_node_or_null("LevelManager")
	if lm:
		if GameState.game_over.is_connected(lm._on_game_over):
			GameState.game_over.disconnect(lm._on_game_over)
		if GameState.level_won.is_connected(lm._on_level_won):
			GameState.level_won.disconnect(lm._on_level_won)

	if not GameState.level_won.is_connected(_on_test_level_won):
		GameState.level_won.connect(_on_test_level_won)
	if not GameState.game_over.is_connected(_on_test_game_over):
		GameState.game_over.connect(_on_test_game_over)

	var scene = load("res://scenes/levels/Level2_Optic.tscn")
	_level_instance = scene.instantiate()
	add_child(_level_instance)


func after_each():
	if _level_instance:
		_level_instance.queue_free()
		_level_instance = null

	if GameState.level_won.is_connected(_on_test_level_won):
		GameState.level_won.disconnect(_on_test_level_won)
	if GameState.game_over.is_connected(_on_test_game_over):
		GameState.game_over.disconnect(_on_test_game_over)

	var lm = get_tree().root.get_node_or_null("LevelManager")
	if lm:
		if not GameState.game_over.is_connected(lm._on_game_over):
			GameState.game_over.connect(lm._on_game_over)
		if not GameState.level_won.is_connected(lm._on_level_won):
			GameState.level_won.connect(lm._on_level_won)

	GameState.reset_state()


func _on_test_level_won():
	_level_won_emitted = true


func _on_test_game_over(_reason: String):
	_game_over_emitted = true


func test_level2_instantiation():
	assert_not_null(_level_instance, "Level 2 instance should be created")
	assert_eq(_level_instance.letters_to_type.size(), 10, "Should generate 10 target letters")
	assert_eq(_level_instance.correct_count, 0, "Initial correct count should be 0")
	assert_eq(_level_instance.current_index, 0, "Initial index should be 0")
	assert_eq(_level_instance.focus_level, 5.0, "Initial focus level should be 5.0")


func test_focus_controls_and_drift():
	_level_instance.focus_level = 5.0
	var event_up = InputEventKey.new()
	event_up.keycode = KEY_UP
	event_up.pressed = true
	_level_instance._unhandled_input(event_up)
	assert_eq(_level_instance.focus_level, 4.5, "Pressing UP decreases focus level")

	var event_down = InputEventKey.new()
	event_down.keycode = KEY_DOWN
	event_down.pressed = true
	_level_instance._unhandled_input(event_down)
	assert_eq(_level_instance.focus_level, 5.0, "Pressing DOWN increases focus level")

	# Test drift in _process
	_level_instance._process(1.0)
	assert_true(_level_instance.focus_level > 5.0, "Focus level drifts upwards over time")


func test_high_blur_stress_increase():
	_level_instance.focus_level = 8.0
	var initial_stress = GameState.stress
	_level_instance._process(1.0)
	assert_true(GameState.stress > initial_stress, "High blur level increases stress")


func test_typing_correct_and_wrong_letters():
	var target = _level_instance.letters_to_type[0]
	_level_instance._type_letter(target)
	assert_eq(_level_instance.correct_count, 1, "Correct letter increments correct count")
	assert_eq(_level_instance.current_index, 1, "Current index advances")

	var wrong_letter = "Z" if target != "Z" else "A"
	var initial_stress = GameState.stress
	_level_instance._type_letter(wrong_letter)
	assert_eq(_level_instance.correct_count, 1, "Wrong letter does not increment correct count")
	assert_eq(_level_instance.current_index, 2, "Current index advances")
	assert_true(GameState.stress > initial_stress, "Wrong letter increases stress")


func test_win_condition_at_least_9_correct():
	_level_instance.letters_to_type = ["C", "C", "C", "C", "C", "C", "C", "C", "C", "C"]
	for i in range(10):
		_level_instance._type_letter("C")

	assert_eq(_level_instance.correct_count, 10, "10 correct letters")
	assert_true(_level_won_emitted, "level_won signal should be emitted on win")


func test_lose_condition_less_than_9_correct():
	_level_instance.letters_to_type = ["C", "C", "C", "C", "C", "C", "C", "C", "C", "C"]
	for i in range(5):
		_level_instance._type_letter("C")
	for i in range(5):
		_level_instance._type_letter("X")

	assert_eq(_level_instance.correct_count, 5, "5 correct letters")
	assert_true(_game_over_emitted, "game_over signal should be emitted on failure")
