class_name UIManager
extends CanvasLayer

## UIManager handles real-time HUD updates (stress meter, level indicators, objectives),
## smooth screen transitions, and win/lose screen overlays with restart/navigation options.

signal transition_finished
signal restart_requested
signal next_level_requested
signal main_menu_requested

const LEVEL_DATA: Dictionary = {
	1: {
		"title": "Level 1: Olfactory Nerve Exam",
		"objective": "Identify all scent vials accurately without overwhelming the patient."
	},
	2: {
		"title": "Level 2: Optic Nerve Exam",
		"objective": "Examine visual fields and chart acuity accurately."
	},
	3: {
		"title": "Level 3: Oculomotor & Eye Movement",
		"objective": "Track pupil response and coordinate eye movements."
	},
	4: {
		"title": "Level 4: Trigeminal Nerve Exam",
		"objective": "Test facial sensation and jaw muscle resistance."
	}
}

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@export var fade_duration: float = 0.4

var _time_elapsed: float = 0.0
var _is_timer_running: bool = true
var _active_tween: Tween = null

@onready var stress_bar: ProgressBar = (
	$HUD/Margin/VBox/TopRow/StressBox/StressProgressBar
	if has_node("HUD/Margin/VBox/TopRow/StressBox/StressProgressBar")
	else null
)
@onready var stress_value_label: Label = (
	$HUD/Margin/VBox/TopRow/StressBox/StressValueLabel
	if has_node("HUD/Margin/VBox/TopRow/StressBox/StressValueLabel")
	else null
)
@onready var level_indicator_label: Label = (
	$HUD/Margin/VBox/TopRow/LevelIndicatorLabel
	if has_node("HUD/Margin/VBox/TopRow/LevelIndicatorLabel")
	else null
)
@onready var timer_label: Label = (
	$HUD/Margin/VBox/TopRow/TimerLabel
	if has_node("HUD/Margin/VBox/TopRow/TimerLabel")
	else null
)
@onready var objective_text_label: Label = (
	$HUD/Margin/VBox/ObjectiveBox/ObjectiveTextLabel
	if has_node("HUD/Margin/VBox/ObjectiveBox/ObjectiveTextLabel")
	else null
)

@onready var win_screen: Control = $WinScreen if has_node("WinScreen") else null
@onready var win_title_label: Label = (
	$WinScreen/PanelContainer/VBox/TitleLabel
	if has_node("WinScreen/PanelContainer/VBox/TitleLabel")
	else null
)
@onready var win_next_button: Button = (
	$WinScreen/PanelContainer/VBox/BtnBox/NextButton
	if has_node("WinScreen/PanelContainer/VBox/BtnBox/NextButton")
	else null
)
@onready var win_restart_button: Button = (
	$WinScreen/PanelContainer/VBox/BtnBox/RestartButton
	if has_node("WinScreen/PanelContainer/VBox/BtnBox/RestartButton")
	else null
)
@onready var win_main_menu_button: Button = (
	$WinScreen/PanelContainer/VBox/BtnBox/MainMenuButton
	if has_node("WinScreen/PanelContainer/VBox/BtnBox/MainMenuButton")
	else null
)

@onready var lose_screen: Control = $LoseScreen if has_node("LoseScreen") else null
@onready var lose_reason_label: Label = (
	$LoseScreen/PanelContainer/VBox/ReasonLabel
	if has_node("LoseScreen/PanelContainer/VBox/ReasonLabel")
	else null
)
@onready var lose_restart_button: Button = (
	$LoseScreen/PanelContainer/VBox/BtnBox/RestartButton
	if has_node("LoseScreen/PanelContainer/VBox/BtnBox/RestartButton")
	else null
)
@onready var lose_main_menu_button: Button = (
	$LoseScreen/PanelContainer/VBox/BtnBox/MainMenuButton
	if has_node("LoseScreen/PanelContainer/VBox/BtnBox/MainMenuButton")
	else null
)

@onready var transition_overlay: ColorRect = (
	$TransitionOverlay if has_node("TransitionOverlay") else null
)


func _ready() -> void:
	# Connect to GameState signals
	if not GameState.stress_changed.is_connected(_on_stress_changed):
		GameState.stress_changed.connect(_on_stress_changed)
	if not GameState.level_completed.is_connected(_on_level_completed):
		GameState.level_completed.connect(_on_level_completed)
	if not GameState.game_over.is_connected(_on_game_over):
		GameState.game_over.connect(_on_game_over)

	# Connect Win screen button signals
	if win_next_button:
		win_next_button.pressed.connect(_on_win_next_pressed)
	if win_restart_button:
		win_restart_button.pressed.connect(_on_win_restart_pressed)
	if win_main_menu_button:
		win_main_menu_button.pressed.connect(_on_main_menu_pressed)

	# Connect Lose screen button signals
	if lose_restart_button:
		lose_restart_button.pressed.connect(_on_lose_restart_pressed)
	if lose_main_menu_button:
		lose_main_menu_button.pressed.connect(_on_main_menu_pressed)

	# Initialize screens visibility
	if win_screen:
		win_screen.hide()
	if lose_screen:
		lose_screen.hide()

	if transition_overlay:
		transition_overlay.color.a = 0.0
		transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Initialize HUD displays
	update_stress_display(GameState.stress)
	update_level_display(GameState.current_level_id)


func _exit_tree() -> void:
	if GameState.stress_changed.is_connected(_on_stress_changed):
		GameState.stress_changed.disconnect(_on_stress_changed)
	if GameState.level_completed.is_connected(_on_level_completed):
		GameState.level_completed.disconnect(_on_level_completed)
	if GameState.game_over.is_connected(_on_game_over):
		GameState.game_over.disconnect(_on_game_over)


func _process(delta: float) -> void:
	if _is_timer_running:
		_time_elapsed += delta
		_update_timer_display()


# --- Public Methods ---

## Updates the stress visual bar and numeric value.
func update_stress_display(stress: float) -> void:
	if stress_bar:
		stress_bar.value = stress
	if stress_value_label:
		stress_value_label.text = "%.1f / %.1f" % [stress, GameState.MAX_STRESS]


## Updates level title indicator and objective text for the specified level ID.
func update_level_display(level_id: int) -> void:
	var info: Dictionary = LEVEL_DATA.get(level_id, {
		"title": "Level %d" % level_id,
		"objective": "Complete the examination."
	})
	set_level_info(level_id, info["title"])
	set_objective(info["objective"])


## Sets the level indicator text directly.
func set_level_info(_level_id: int, title: String) -> void:
	if level_indicator_label:
		level_indicator_label.text = title


## Sets the objective display text.
func set_objective(objective_text: String) -> void:
	if objective_text_label:
		objective_text_label.text = objective_text


## Shows the win screen overlay.
func show_win_screen() -> void:
	_is_timer_running = false
	if win_screen:
		win_screen.show()


## Shows the lose screen overlay with a specified reason.
func show_lose_screen(reason: String = "") -> void:
	_is_timer_running = false
	if lose_reason_label and not reason.is_empty():
		lose_reason_label.text = reason
	if lose_screen:
		lose_screen.show()


## Smoothly fades out the screen (to solid color).
func fade_out(duration: float = -1.0) -> void:
	if not transition_overlay:
		transition_finished.emit()
		return

	var time: float = fade_duration if duration < 0.0 else duration
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	if _active_tween and _active_tween.is_running():
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.tween_property(transition_overlay, "color:a", 1.0, time)
	_active_tween.tween_callback(func():
		transition_finished.emit()
	)


## Smoothly fades in the screen (to transparent).
func fade_in(duration: float = -1.0) -> void:
	if not transition_overlay:
		transition_finished.emit()
		return

	var time: float = fade_duration if duration < 0.0 else duration

	if _active_tween and _active_tween.is_running():
		_active_tween.kill()

	_active_tween = create_tween()
	_active_tween.tween_property(transition_overlay, "color:a", 0.0, time)
	_active_tween.tween_callback(func():
		transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition_finished.emit()
	)


## Performs a smooth level transition to target level_id.
func transition_to_level(level_id: int, duration: float = -1.0) -> void:
	var time: float = fade_duration if duration < 0.0 else duration
	fade_out(time)
	await transition_finished

	GameState.reset_stress()
	_time_elapsed = 0.0
	_is_timer_running = true

	var level_mgr = get_tree().root.get_node_or_null("LevelManager")
	if level_mgr and level_mgr.has_method("load_level"):
		level_mgr.load_level(level_id)
	else:
		GameState.set_current_level(level_id)

	if win_screen:
		win_screen.hide()
	if lose_screen:
		lose_screen.hide()

	update_level_display(level_id)
	fade_in(time)


# --- Signal Handlers ---

func _on_stress_changed(new_stress: float, _delta: float) -> void:
	update_stress_display(new_stress)


func _on_level_completed(_level_id: int) -> void:
	show_win_screen()


func _on_game_over(reason: String) -> void:
	show_lose_screen(reason)


func _on_win_next_pressed() -> void:
	next_level_requested.emit()
	var next_id: int = GameState.current_level_id + 1
	if next_id <= GameState.MAX_LEVEL_ID:
		transition_to_level(next_id)
	else:
		_on_main_menu_pressed()


func _on_win_restart_pressed() -> void:
	restart_requested.emit()
	transition_to_level(GameState.current_level_id)


func _on_lose_restart_pressed() -> void:
	restart_requested.emit()
	GameState.is_game_over = false
	transition_to_level(GameState.current_level_id)


func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()
	fade_out()
	await transition_finished
	GameState.reset_state()
	get_tree().call_deferred("change_scene_to_file", MAIN_MENU_SCENE)


func _update_timer_display() -> void:
	if timer_label:
		var minutes: int = int(_time_elapsed) / 60
		var seconds: int = int(_time_elapsed) % 60
		timer_label.text = "T: %02d:%02d" % [minutes, seconds]
