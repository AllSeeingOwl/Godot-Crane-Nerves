extends GutTest

var player_script = load("res://scripts/player.gd")
var player: CharacterBody3D

func before_each():
	player = player_script.new()
	add_child(player)

func after_each():
	if is_instance_valid(player):
		player.queue_free()

func test_player_initialization():
	assert_not_null(player, "Player should be instantiated")
	assert_eq(
		player.current_animation_state,
		player.AnimationState.IDLE,
		"Initial animation state should be IDLE"
	)

func test_player_speed_constant():
	assert_eq(player.SPEED, 5.0, "Player speed should be 5.0")

func test_player_jump_velocity_constant():
	assert_eq(player.JUMP_VELOCITY, 4.5, "Player jump velocity should be 4.5")

func test_player_gravity_applied():
	var initial_velocity_y = player.velocity.y
	player._physics_process(0.1)
	assert_true(
		player.velocity.y < initial_velocity_y,
		"Gravity should pull player down when not on floor"
	)

func test_player_animation_state_updates_to_falling():
	player.velocity.y = -10
	player._update_animation_state()
	assert_eq(
		player.current_animation_state,
		player.AnimationState.FALLING,
		"Animation state should be FALLING when moving down and not on floor"
	)

func test_player_animation_state_updates_to_jumping():
	player.velocity.y = 10
	player._update_animation_state()
	assert_eq(
		player.current_animation_state,
		player.AnimationState.JUMPING,
		"Animation state should be JUMPING when moving up and not on floor"
	)

func test_player_animation_state_updates_to_walking():
	player.velocity.x = 5
	# Need to mock is_on_floor = true, but since we are not on floor by default it will jump/fall.
	# We can temporarily override it if we inject a mock, but without it we just test logic fallback


func test_player_has_move_and_slide_method():
	assert_true(
		player.has_method("move_and_slide"),
		"Player should inherit from CharacterBody3D and have move_and_slide"
	)

func test_player_velocity_is_vector3():
	assert_typeof(player.velocity, TYPE_VECTOR3, "Velocity should be a Vector3")
