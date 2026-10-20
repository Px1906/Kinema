class_name PauseMenu
extends CanvasLayer

signal restart_full_requested
signal restart_checkpoint_requested
signal exit_requested

var has_checkpoint := false

@onready var _dimmer: ColorRect = $Dimmer
@onready var _center: CenterContainer = $CenterContainer
@onready var _main_panel: PanelContainer = %MainPanel
@onready var _restart_panel: PanelContainer = %RestartPanel
@onready var _options_menu: OptionsMenu = %OptionsMenu
@onready var _formulas_panel: FormulasPanel = %FormulasPanel
@onready var _resume_button: Button = %ResumeButton
@onready var _formulas_button: Button = %FormulasButton
@onready var _restart_button: Button = %RestartButton
@onready var _options_button: Button = %OptionsButton
@onready var _exit_button: Button = %ExitButton
@onready var _restart_full_button: Button = %RestartFullButton
@onready var _restart_checkpoint_button: Button = %RestartCheckpointButton
@onready var _restart_back_button: Button = %RestartBackButton


func _ready() -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_unpause()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	_show_main()
	get_tree().paused = true


func _unpause() -> void:
	_hide_all()
	get_tree().paused = false


func _show_main() -> void:
	_dimmer.show()
	_center.show()
	_main_panel.show()
	_restart_panel.hide()
	_options_menu.hide()
	_formulas_panel.hide()
	_resume_button.grab_focus()


func _hide_all() -> void:
	_dimmer.hide()
	_center.hide()
	_main_panel.hide()
	_restart_panel.hide()
	_options_menu.hide()
	_formulas_panel.hide()


func _open_options() -> void:
	_main_panel.hide()
	_options_menu.open()


func _open_formulas() -> void:
	_main_panel.hide()
	_formulas_panel.open()


func _open_restart() -> void:
	_main_panel.hide()
	_restart_panel.show()
	_restart_full_button.grab_focus()


func _on_sub_closed() -> void:
	_show_main()


func _on_restart_pressed() -> void:
	if has_checkpoint:
		_open_restart()
	else:
		_unpause()
		restart_full_requested.emit()


func _on_restart_full() -> void:
	_unpause()
	restart_full_requested.emit()


func _on_restart_checkpoint() -> void:
	_unpause()
	restart_checkpoint_requested.emit()


func _on_exit() -> void:
	_unpause()
	exit_requested.emit()
