extends GutTest

var ragdoll_scene = preload("res://scenes/player/RagdollCharacter.tscn")
var ragdoll: RagdollCharacter

func before_each():
	GameState.reset_stress()
	if GameState.game_over.is_connected(LevelManager._on_game_over):
		GameState.game_over.disconnect(LevelManager._on_game_over)
	ragdoll = ragdoll_scene.instantiate()
	add_child(ragdoll)

func after_each():
	if ragdoll:
		ragdoll.queue_free()
	GameState.reset_stress()
	if not GameState.game_over.is_connected(LevelManager._on_game_over):
		GameState.game_over.connect(LevelManager._on_game_over)

func test_ragdoll_initialization():
	assert_not_null(ragdoll.torso, "Torso should exist")
	assert_not_null(ragdoll.head, "Head should exist")
	assert_not_null(ragdoll.shoulder_l, "Shoulder joint should exist")
	assert_not_null(ragdoll.knee_r, "Knee joint should exist")

func test_push_body_part():
	watch_signals(ragdoll)
	var initial_vel = ragdoll.torso.linear_velocity
	ragdoll.push_body_part("Torso", Vector3(0, 5, 0))
	assert_signal_emitted(ragdoll, "ragdoll_manipulated")
	assert_ne(
		ragdoll.torso.linear_velocity,
		initial_vel,
		"Torso linear velocity should change after impulse"
	)

func test_freeze_ragdoll():
	ragdoll.set_frozen(true)
	assert_true(ragdoll.torso.freeze, "Torso should be frozen")
	assert_true(ragdoll.head.freeze, "Head should be frozen")

func test_state_persistence():
	ragdoll.torso.linear_velocity = Vector3(1.5, 2.0, 3.5)
	var saved_state = ragdoll.get_ragdoll_state()
	assert_true(saved_state.has("bodies"), "Saved state should contain bodies")
	assert_true(saved_state["bodies"].has("Torso"), "Saved state should contain Torso data")

	ragdoll.torso.linear_velocity = Vector3.ZERO
	ragdoll.load_ragdoll_state(saved_state)
	assert_eq(
		ragdoll.torso.linear_velocity,
		Vector3(1.5, 2.0, 3.5),
		"Torso linear velocity should be restored"
	)

func test_stress_generation():
	watch_signals(ragdoll)
	ragdoll.torso.linear_velocity = Vector3(100.0, 0, 0)
	ragdoll._physics_process(0.016)
	assert_gt(GameState.stress, 0.0, "Global stress should increase from ragdoll acceleration")
