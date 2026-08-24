extends GutTest

var enemy_script = load("res://scripts/base_enemy.gd")
var enemy: BaseEnemy

func before_each():
	enemy = enemy_script.new()
	add_child(enemy)
	enemy._ready()

func after_each():
	if is_instance_valid(enemy):
		enemy.queue_free()

func test_enemy_initialization():
	assert_not_null(enemy, "Enemy should be instantiated")
	assert_eq(enemy.current_health, enemy.max_health, "Current health should equal max health on initialization")
	assert_eq(enemy.movement_speed, 3.0, "Movement speed should be 3.0 by default")

func test_enemy_take_damage():
	var initial_health = enemy.current_health
	enemy.take_damage(20)
	assert_eq(enemy.current_health, initial_health - 20, "Health should decrease by 20 after taking 20 damage")

func test_enemy_death():
	enemy.take_damage(enemy.max_health)
	assert_eq(enemy.current_health, 0.0, "Health should be 0")
	assert_true(enemy.is_queued_for_deletion(), "Enemy should be queued for deletion after health reaches 0")

func test_enemy_has_take_damage_method():
	assert_true(enemy.has_method("take_damage"), "Enemy should have take_damage method")
