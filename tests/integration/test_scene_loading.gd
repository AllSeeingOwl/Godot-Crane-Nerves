extends GutTest

func test_main_scene_instantiation():
	var main_scene = load("res://scenes/Main.tscn")
	if main_scene:
		var instance = main_scene.instantiate()
		assert_not_null(instance, "Main scene should instantiate successfully")
		instance.free()
	else:
		pending("Main.tscn does not exist yet")
