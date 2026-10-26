class_name OptionsMenu
extends PanelContainer

signal closed

@onready var _sliders: Dictionary = {
	AudioSettings.BUS_MASTER: %MasterSlider as HSlider,
	AudioSettings.BUS_SFX: %SFXSlider as HSlider,
	AudioSettings.BUS_MUSIC: %MusicSlider as HSlider,
	AudioSettings.BUS_UI: %UISlider as HSlider,
}
@onready var _window_button: Button = %WindowButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	for bus_name: StringName in _sliders:
		(_sliders[bus_name] as HSlider).value_changed.connect(_on_volume_changed.bind(bus_name))
	_window_button.pressed.connect(_on_window_toggled)
	_back_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_sync_sliders()
	_sync_window_label()
	show()
	_back_button.grab_focus()


func close() -> void:
	AudioSettings.save_settings()
	hide()
	closed.emit()


func _sync_sliders() -> void:
	for bus_name: StringName in _sliders:
		(_sliders[bus_name] as HSlider).value = AudioSettings.get_bus_volume_percent(bus_name)


func _sync_window_label() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	_window_button.text = "Janela: Tela cheia" if is_fullscreen else "Janela: Modo janela"


func _on_volume_changed(value: float, bus_name: StringName) -> void:
	AudioSettings.apply_bus_volume(bus_name, value)


func _on_window_toggled() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_sync_window_label()
