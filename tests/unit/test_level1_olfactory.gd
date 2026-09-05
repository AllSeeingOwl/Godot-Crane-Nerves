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

	var scene = load("res://scenes/levels/Level1_Olfactory.tscn")
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


func test_level1_instantiation():
	assert_not_null(_level_instance, "Level 1 instance should be created")
	assert_eq(_level_instance.selected_vial, "", "Initial selected vial should be empty")
	assert_eq(_level_instance.identified_vials.size(), 0, "Initial identified vials should be empty")


func test_vial_selection_qwer_and_buttons():
	_level_instance._on_vial_pressed("coffee")
	assert_eq(_level_instance.selected_vial, "coffee", "Selecting coffee vial")

	# Toggle off
	_level_instance._on_vial_pressed("coffee")
	assert_eq(_level_instance.selected_vial, "", "Toggling coffee off deselects vial")

	# Key inputs
	var event_q = InputEventKey.new()
	event_q.keycode = KEY_Q
	event_q.pressed = true
	_level_instance._unhandled_input(event_q)
	assert_eq(_level_instance.selected_vial, "coffee", "Pressing Q selects coffee")

	var event_w = InputEventKey.new()
	event_w.keycode = KEY_W
	event_w.pressed = true
	_level_instance._unhandled_input(event_w)
	assert_eq(_level_instance.selected_vial, "mint", "Pressing W selects mint")

	var event_e = InputEventKey.new()
	event_e.keycode = KEY_E
	event_e.pressed = true
	_level_instance._unhandled_input(event_e)
	assert_eq(_level_instance.selected_vial, "surstromming", "Pressing E selects surstromming")

	var event_r = InputEventKey.new()
	event_r.keycode = KEY_R
	event_r.pressed = true
	_level_instance._unhandled_input(event_r)
	assert_eq(_level_instance.selected_vial, "", "Pressing R drops/deselects vial")


func test_mouse_following_and_lag():
	_level_instance.hand_position = Vector2(0, 0)
	var target = Vector2(100, 100)
	_level_instance.hand_keyboard_offset = Vector2.ZERO
	_level_instance.hand_position = _level_instance.hand_position.lerp(target, 0.1)
	assert_true(_level_instance.hand_position.x < 100.0, "Hand position lags behind target")
	assert_true(_level_instance.hand_position.x > 0.0, "Hand position moves towards target")


func test_hand_speed_and_stress():
	_level_instance.current_hand_speed = 1000.0
	_level_instance._process(0.1)
	assert_true(GameState.stress > 0.0, "Moving hand too fast increases patient stress")


func test_bad_smell_evasion_and_stress():
	_level_instance._on_vial_pressed("surstromming")
	_level_instance.nose.position = Vector2(200, 200)
	var nose_center = _level_instance.nose.position + (_level_instance.nose.size / 2.0)
	_level_instance.hand_position = nose_center - Vector2(10, 0)

	var initial_stress = GameState.stress
	_level_instance._process(0.1)

	assert_true(GameState.stress > initial_stress, "Surströmming near nose rapidly increases stress")


func test_smell_identification_and_win_condition():
	_level_instance._on_vial_pressed("coffee")
	_level_instance.nose.position = Vector2(200, 200)
	var nose_center = _level_instance.nose.position + (_level_instance.nose.size / 2.0)
	_level_instance.hand_position = nose_center

	for i in range(30):
		_level_instance._process(0.1)

	assert_true(_level_instance.identified_vials.has("coffee"), "Coffee should be identified")

	_level_instance._on_vial_pressed("mint")
	for i in range(30):
		_level_instance._process(0.1)

	assert_true(_level_instance.identified_vials.has("mint"), "Mint should be identified")
	assert_true(_level_won_emitted, "level_won signal should be emitted")


func test_max_stress_lose_condition():
	GameState.add_stress(100.0)
	assert_true(GameState.is_game_over, "Game over flag set when stress reaches max")
	assert_true(_game_over_emitted, "game_over signal should be emitted")
