extends "res://addons/gut/hook_script.gd"

## Runs once before the whole GUT suite.


func run() -> void:
	# Level tests win and lose levels; don't let LevelManager swap out the test scene.
	var level_manager = gut.get_tree().root.get_node_or_null("LevelManager")
	if level_manager:
		level_manager.scene_changes_enabled = false
