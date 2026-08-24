extends GutTest

var game_logic_script = load("res://scripts/game_logic.gd")
var game_logic

func before_each():
	game_logic = game_logic_script.new()
	add_child(game_logic)

func after_each():
	if is_instance_valid(game_logic):
		game_logic.queue_free()

func test_game_logic_initialization():
	assert_not_null(game_logic, "GameLogic should be instantiated")
	assert_eq(game_logic.current_score, 0, "Initial score should be 0")

func test_add_score_positive():
	game_logic.add_score(10)
	assert_eq(game_logic.current_score, 10, "Score should be 10 after adding 10")
	game_logic.add_score(5)
	assert_eq(game_logic.current_score, 15, "Score should be 15 after adding 5 more")

func test_add_score_negative():
	game_logic.add_score(-5)
	assert_eq(game_logic.current_score, 0, "Score should remain 0 when adding negative amount")

func test_reset_score():
	game_logic.add_score(50)
	assert_eq(game_logic.current_score, 50, "Score should be 50")
	game_logic.reset_score()
	assert_eq(game_logic.current_score, 0, "Score should be 0 after reset")

func test_game_logic_add_zero_score():
	game_logic.add_score(0)
	assert_eq(game_logic.current_score, 0, "Score should remain 0 when adding 0")
