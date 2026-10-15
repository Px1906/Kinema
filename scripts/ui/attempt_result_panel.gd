class_name AttemptResultPanel
extends CanvasLayer

signal retry_requested

@onready var _title_label: Label = %TitleLabel
@onready var _message_label: Label = %MessageLabel
@onready var _retry_button: Button = %RetryButton


func _ready() -> void:
	_retry_button.pressed.connect(_on_retry_pressed)
	hide_result()


func show_result(title: String, message: String) -> void:
	_title_label.text = title
	_message_label.text = message
	show()


func hide_result() -> void:
	hide()


func _on_retry_pressed() -> void:
	retry_requested.emit()
	hide_result()
