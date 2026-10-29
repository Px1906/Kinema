class_name FormulasPanel
extends VBoxContainer

signal closed

@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_apply_font_sizes()
	_back_button.pressed.connect(close)


func _apply_font_sizes() -> void:
	FontSettings.apply($Title, FontSettings.ui_title)
	FontSettings.apply(_back_button, FontSettings.ui_button)
	var list: VBoxContainer = $ScrollContainer/FormulasList
	for child: Control in list.get_children():
		if child is Label:
			var is_title := child.name.ends_with("Title")
			FontSettings.apply(child, FontSettings.ui_subtitle if is_title else FontSettings.ui_body)


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
