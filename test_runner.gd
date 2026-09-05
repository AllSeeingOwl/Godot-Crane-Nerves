extends SceneTree

func _init():
	print("TEST_START")
	var game_state = root.get_node_or_null("GameState")
	if not game_state:
		var gs_script = load("res://scripts/game_state.gd")
		game_state = gs_script.new()
		game_state.name = "GameState"
		root.add_child(game_state)

	var level_manager = root.get_node_or_null("LevelManager")
	if not level_manager:
		var lm_script = load("res://scripts/level_manager.gd")
		level_manager = lm_script.new()
		level_manager.name = "LevelManager"
		root.add_child(level_manager)

	game_state.reset_stress()

	var ragdoll_scene = load("res://scenes/player/RagdollCharacter.tscn")
	var ragdoll = ragdoll_scene.instantiate()
	root.add_child(ragdoll)

	print("Testing push_body_part...")
	ragdoll.push_body_part("Torso", Vector3(0, 5, 0))

	print("Testing set_frozen...")
	ragdoll.set_frozen(true)
	assert(ragdoll.torso.freeze == true)

	print("Testing get_ragdoll_state & load_ragdoll_state...")
	var state = ragdoll.get_ragdoll_state()
	ragdoll.load_ragdoll_state(state)

	ragdoll.queue_free()
	print("All ragdoll tests completed successfully!")
	quit(0)
