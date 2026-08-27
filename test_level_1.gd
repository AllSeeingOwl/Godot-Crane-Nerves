extends SceneTree

func _init():
	var level_scene = preload("res://scenes/levels/level_1_olfactory.tscn")
	var instance = level_scene.instantiate()
	print("Scene instanced successfully")
	quit()
