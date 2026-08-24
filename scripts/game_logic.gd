class_name GameLogic
extends Node

var current_score: int = 0

func add_score(amount: int):
	if amount > 0:
		current_score += amount

func reset_score():
	current_score = 0
