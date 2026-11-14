extends GutTest

var overlay: LevelOverlay


func before_each() -> void:
	overlay = LevelOverlay.new()
	overlay.pause_tree = false
	add_child(overlay)


func after_each() -> void:
	if overlay:
		overlay.free()


func test_starts_with_no_panel_open() -> void:
	assert_false(overlay.is_panel_open(), "No panel at the start of a level")
	assert_eq(LevelOverlay.find_in(get_tree()), overlay, "Findable through its group")


func test_passed_screen_offers_next_restart_and_menu() -> void:
	overlay.show_passed("Level 2: Optic Nerve", true)
	assert_eq(overlay.screen, LevelOverlay.Screen.PASSED)
	assert_eq(overlay.title_text(), "EXAM PASSED")
	assert_string_contains(overlay.message_text(), "Level 2: Optic Nerve")
	assert_eq(overlay.button_labels(), ["Next Level", "Restart", "Main Menu"])


func test_passing_the_last_level_shows_the_complete_screen() -> void:
	overlay.show_passed("Level 9: Hypoglossal Nerve", false)
	assert_eq(overlay.screen, LevelOverlay.Screen.COMPLETE)
	assert_eq(overlay.button_labels(), ["Play Again", "Main Menu"])


func test_failed_screen_shows_the_reason() -> void:
	overlay.show_failed("You poked the patient in the eye!")
	assert_eq(overlay.screen, LevelOverlay.Screen.FAILED)
	assert_eq(overlay.message_text(), "You poked the patient in the eye!")
	assert_eq(overlay.button_labels(), ["Retry", "Main Menu"])


func test_failed_screen_has_a_fallback_reason() -> void:
	overlay.show_failed("")
	assert_false(overlay.message_text().is_empty(), "Never shows an empty reason")


func test_pause_menu_opens_and_closes() -> void:
	overlay.show_paused()
	assert_eq(overlay.screen, LevelOverlay.Screen.PAUSED)
	assert_eq(overlay.button_labels(), ["Resume", "Restart", "Main Menu"])
	overlay.hide_panel()
	assert_false(overlay.is_panel_open(), "Resume closes the menu")


func test_reopening_replaces_the_buttons() -> void:
	overlay.show_paused()
	overlay.show_failed("Too much stress")
	assert_eq(overlay.button_labels(), ["Retry", "Main Menu"], "No leftovers")


func test_every_level_gets_an_overlay() -> void:
	var level: Node = load("res://scenes/levels/Level4_Trigeminal.tscn").instantiate()
	add_child(level)
	var found := false
	for child in level.get_children():
		if child is LevelOverlay:
			found = true
	assert_true(found, "BaseLevel adds the overlay")
	level.free()
