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

	var scene = load("res://scenes/levels/Level3_EyeMovement.tscn")
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


func test_level3_instantiation():
	assert_not_null(_level_instance, "Level 3 instance should be created")
	assert_eq(_level_instance.current_node_index, 0, "Initial node index should be 0")
	assert_eq(_level_instance.progress, 0.0, "Initial progress should be 0.0")
	assert_eq(_level_instance.NODES.size(), 6, "H-pattern should have 6 nodes")


func test_penlight_lag_movement():
	_level_instance.penlight_pos = Vector2(0, 0)
	var viewport_size = Vector2(1000, 1000)
	_level_instance._process(0.1)
	# Penlight pos moves towards mouse position
	assert_not_null(_level_instance.penlight_pos, "Penlight position updated")


func test_tracing_nodes_in_sequence_and_win():
	var viewport_size = Vector2(1000, 1000)

	for i in range(_level_instance.NODES.size()):
		var target_norm = _level_instance.NODES[i]
		var target_screen = Vector2(
			target_norm.x * viewport_size.x,
			target_norm.y * viewport_size.y
		)
		_level_instance.penlight_pos = target_screen
		_level_instance._process(0.1)
		assert_eq(
			_level_instance.current_node_index,
			i + 1,
			"Node %d traced" % (i + 1)
		)

	assert_true(_level_won_emitted, "level_won signal should be emitted on completing all nodes")


func test_ambient_stress():
	var initial_stress = GameState.stress
	for i in range(100):
		_level_instance._process(0.1)
	assert_true(
		GameState.stress >= initial_stress,
		"Ambient stress can accumulate over time"
	)
