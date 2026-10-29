class_name AttemptResultPanel
extends CanvasLayer

signal retry_requested
signal exit_requested

@onready var _title_label: Label = %TitleLabel
@onready var _message_label: Label = %MessageLabel
@onready var _retry_button: Button = %RetryButton
@onready var _exit_button: Button = %ExitButton


func _ready() -> void:
	_retry_button.pressed.connect(_on_retry_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)
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


func _on_exit_pressed() -> void:
	exit_requested.emit()
