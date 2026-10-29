class_name PauseMenu
extends CanvasLayer

signal restart_full_requested
signal restart_checkpoint_requested
signal exit_requested

var has_checkpoint := false
var _qte_active := false

@onready var _blur_rect: ColorRect = $BlurRect
@onready var _center: CenterContainer = $CenterContainer
@onready var _main_panel: VBoxContainer = %MainPanel
@onready var _restart_panel: VBoxContainer = %RestartPanel
@onready var _options_menu: OptionsMenu = %OptionsMenu
@onready var _formulas_panel: FormulasPanel = %FormulasPanel
@onready var _resume_button: BaseButton = %ResumeButton
@onready var _formulas_button: Button = %FormulasButton
@onready var _restart_button: BaseButton = %RestartButton
@onready var _options_button: Button = %OptionsButton
@onready var _exit_button: Button = %ExitButton
@onready var _restart_full_button: Button = %RestartFullButton
@onready var _restart_checkpoint_button: Button = %RestartCheckpointButton
@onready var _restart_back_button: Button = %RestartBackButton


func _ready() -> void:
	_apply_font_sizes()
	_resume_button.pressed.connect(_unpause)
	_formulas_button.pressed.connect(_open_formulas)
	_restart_button.pressed.connect(_on_restart_pressed)
	_options_button.pressed.connect(_open_options)
	_exit_button.pressed.connect(_on_exit)
	_restart_full_button.pressed.connect(_on_restart_full)
	_restart_checkpoint_button.pressed.connect(_on_restart_checkpoint)
	_restart_back_button.pressed.connect(_on_sub_closed)
	_options_menu.closed.connect(_on_sub_closed)
	_formulas_panel.closed.connect(_on_sub_closed)
	_hide_all()
	Events.qte_started.connect(func(_b: QteBarrier) -> void: _qte_active = true)
	Events.qte_finished.connect(func(_b: QteBarrier, _c: bool) -> void: _qte_active = false)


func _apply_font_sizes() -> void:
	_main_panel.get_node("Title").add_theme_font_size_override("font_size", FontSettings.ui_title)
	FontSettings.apply(_resume_button, FontSettings.ui_button)
	FontSettings.apply(_restart_button, FontSettings.ui_button)
	FontSettings.apply(_formulas_button, FontSettings.ui_button)
	FontSettings.apply(_options_button, FontSettings.ui_button)
	FontSettings.apply(_exit_button, FontSettings.ui_button)
	_restart_panel.get_node("Title").add_theme_font_size_override("font_size", FontSettings.ui_subtitle)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _qte_active:
			get_viewport().set_input_as_handled()
			return
		if get_tree().paused:
			_unpause()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	_show_main()
	get_tree().paused = true
	UIAudio.play_pause(true)


func _unpause() -> void:
	_close_and_unpause()
	UIAudio.play_pause(false)


func _close_and_unpause() -> void:
	_hide_all()
	get_tree().paused = false


func _show_main() -> void:
	_blur_rect.show()
	_center.show()
	_hide_sub_panels()
	_main_panel.show()
	_resume_button.grab_focus()


func _hide_all() -> void:
	_blur_rect.hide()
	_center.hide()
	_hide_sub_panels()


func _hide_sub_panels() -> void:
	_main_panel.hide()
	_restart_panel.hide()
	_options_menu.hide()
	_formulas_panel.hide()


func _open_options() -> void:
	_hide_sub_panels()
	_options_menu.open()


func _open_formulas() -> void:
	_hide_sub_panels()
	_formulas_panel.open()


func _open_restart() -> void:
	_hide_sub_panels()
	_restart_panel.show()
	_restart_full_button.grab_focus()


func _on_sub_closed() -> void:
	_show_main()


func _on_restart_pressed() -> void:
	if has_checkpoint:
		_open_restart()
	else:
		_close_and_unpause()
		restart_full_requested.emit()


func _on_restart_full() -> void:
	_close_and_unpause()
	restart_full_requested.emit()


func _on_restart_checkpoint() -> void:
	_close_and_unpause()
	restart_checkpoint_requested.emit()


func _on_exit() -> void:
	_close_and_unpause()
	exit_requested.emit()
