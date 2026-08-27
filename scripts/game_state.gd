extends Node

signal stress_changed(new_stress: float, delta: float)
signal game_over(reason: String)
signal level_won

var stress: float = 0.0
var current_level_id: int = 1


func add_stress(amount: float):
	stress += amount
	stress = clamp(stress, 0.0, 100.0)
	stress_changed.emit(stress, amount)

	if stress >= 100.0:
		game_over.emit("Patient got too stressed!")


func reset_stress():
	stress = 0.0
	stress_changed.emit(stress, 0.0)
