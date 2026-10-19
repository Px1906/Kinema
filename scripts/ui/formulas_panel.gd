class_name FormulasPanel
extends PanelContainer

signal closed

@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	show()
	_back_button.grab_focus()


func close() -> void:
	hide()
	closed.emit()
