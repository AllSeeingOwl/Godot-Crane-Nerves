class_name LevelOverlay
extends CanvasLayer

## In-level overlay added to every level by BaseLevel:
## - Always-visible Restart and Menu buttons (top left).
## - Esc pause menu: Resume / Restart / Main Menu.
## - Result screens shown by LevelManager: passed (Next / Restart / Menu), failed with the
##   reason (Retry / Menu), and the final "full exam complete" screen (Play Again / Menu).
## While a panel is open the game is paused; this overlay keeps processing.

enum Screen { NONE, PAUSED, PASSED, FAILED, COMPLETE }

const GROUP: String = "level_overlay"
const PANEL_BG := Color(0.06, 0.08, 0.07, 0.94)
const PANEL_EDGE := Color(0.55, 0.85, 0.6)
const PASS_COLOR := Color(0.5, 1.0, 0.55)
const FAIL_COLOR := Color(1.0, 0.45, 0.4)

## Pause the scene tree while a panel is open. Tests turn this off.
var pause_tree: bool = true
var screen: Screen = Screen.NONE

var _dim: ColorRect
var _panel: PanelContainer
var _title: Label
var _message: Label
var _buttons: HBoxContainer
var _primary: Button


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	_build_corner_buttons()
	_build_panel()
	hide_panel()


## The overlay in the current scene, if there is one.
static func find_in(tree: SceneTree) -> LevelOverlay:
	return tree.get_first_node_in_group(GROUP) as LevelOverlay if tree else null


func show_paused() -> void:
	_open(Screen.PAUSED, "PAUSED", "The patient waits awkwardly.", Color.WHITE)
	_add_button("Resume", hide_panel, true)
	_add_button("Restart", _on_restart)
	_add_button("Main Menu", _on_main_menu)


func show_passed(level_title: String, has_next: bool) -> void:
	if not has_next:
		show_complete()
		return
	_open(
		Screen.PASSED, "EXAM PASSED", "%s\nThe patient survived. Barely." % level_title, PASS_COLOR
	)
	_add_button("Next Level", _on_next, true)
	_add_button("Restart", _on_restart)
	_add_button("Main Menu", _on_main_menu)


func show_failed(reason: String) -> void:
	var text := reason if not reason.is_empty() else "The patient got too stressed."
	_open(Screen.FAILED, "EXAM FAILED", text, FAIL_COLOR)
	_add_button("Retry", _on_restart, true)
	_add_button("Main Menu", _on_main_menu)


func show_complete() -> void:
	_open(
		Screen.COMPLETE,
		"FULL EXAM COMPLETE",
		"All twelve cranial nerves examined.\nThe patient would like to leave now.",
		PASS_COLOR
	)
	_add_button("Play Again", _on_play_again, true)
	_add_button("Main Menu", _on_main_menu)


func hide_panel() -> void:
	screen = Screen.NONE
	_dim.visible = false
	_panel.visible = false
	_set_paused(false)


func is_panel_open() -> bool:
	return screen != Screen.NONE


func message_text() -> String:
	return _message.text


func title_text() -> String:
	return _title.text


func button_labels() -> Array:
	var labels := []
	for child in _buttons.get_children():
		if child is Button and not child.is_queued_for_deletion():
			labels.append(child.text)
	return labels


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).keycode
	if key == KEY_ESCAPE:
		if screen == Screen.NONE:
			show_paused()
		elif screen == Screen.PAUSED:
			hide_panel()
		get_viewport().set_input_as_handled()
	elif (key == KEY_ENTER or key == KEY_KP_ENTER) and is_panel_open() and _primary:
		get_viewport().set_input_as_handled()
		_primary.pressed.emit()


# --- Building ---


func _build_corner_buttons() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(10, 10)
	bar.add_theme_constant_override("separation", 6)
	add_child(bar)
	for spec in [["Restart", _on_restart], ["Menu", _on_main_menu]]:
		var button := Button.new()
		button.text = spec[0]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(84, 30)
		button.pressed.connect(spec[1])
		bar.add_child(button)


func _build_panel() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.add_child(center)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_EDGE
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(28)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	_panel.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 40)
	box.add_child(_title)

	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(400, 0)
	_message.add_theme_font_size_override("font_size", 20)
	box.add_child(_message)

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 12)
	box.add_child(_buttons)


func _open(which: Screen, title: String, message: String, color: Color) -> void:
	screen = which
	_title.text = title
	_title.add_theme_color_override("font_color", color)
	_message.text = message
	for child in _buttons.get_children():
		child.queue_free()
	_primary = null
	_dim.visible = true
	_panel.visible = true
	_set_paused(true)


func _add_button(text: String, action: Callable, primary: bool = false) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(130, 40)
	button.pressed.connect(action)
	_buttons.add_child(button)
	if primary:
		_primary = button
		button.call_deferred("grab_focus")


func _set_paused(paused: bool) -> void:
	if pause_tree and is_inside_tree():
		get_tree().paused = paused


# --- Actions ---


func _on_restart() -> void:
	_set_paused(false)
	LevelManager.restart_level()


func _on_next() -> void:
	_set_paused(false)
	LevelManager.load_level(GameState.current_level_id + 1)


func _on_play_again() -> void:
	_set_paused(false)
	GameState.reset_state()
	LevelManager.load_level(1)


func _on_main_menu() -> void:
	_set_paused(false)
	LevelManager.go_to_main_menu()
