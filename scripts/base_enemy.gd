class_name BaseEnemy
extends CharacterBody3D

@export var max_health: float = 100.0
@export var movement_speed: float = 3.0

var current_health: float

func _ready():
	current_health = max_health

func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	queue_free()
