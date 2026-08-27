extends Node

signal stress_changed(new_stress: float, delta: float)
signal game_over(reason: String)
signal level_won

const LEVEL_LOSE_REASONS: Dictionary = {
	1: "Patient got too stressed from the smells!",
	2: "Patient got too stressed from struggling to see!",
	3: "Patient got too stressed during the eye exam!",
	4: "Patient couldn't tolerate the facial exam!",
	5: "Patient couldn't follow the facial nerve commands!",
	6: "Patient became overwhelmed by the hearing exam!",
	7: "Patient got too stressed from the gag reflex test!",
	8: "Patient got too stressed from the resistance tests!",
	9: "Patient got too stressed from the tongue examination!",
	10: "Total systemic failure! The crisis was too much."
}

var stress: float = 0.0
var current_level_id: int = 1


func add_stress(amount: float):
	stress += amount
	stress = clamp(stress, 0.0, 100.0)
	stress_changed.emit(stress, amount)

	if stress >= 100.0:
		var reason = LEVEL_LOSE_REASONS.get(current_level_id, "Patient got too stressed!")
		game_over.emit(reason)


func reset_stress():
	stress = 0.0
	stress_changed.emit(stress, 0.0)
