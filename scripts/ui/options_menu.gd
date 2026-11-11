class_name OptionsMenu
extends VBoxContainer

signal closed

@onready var _sliders: Dictionary = {
	AudioSettings.BUS_MASTER: %MasterSlider as HSlider,
	AudioSettings.BUS_SFX: %SFXSlider as HSlider,
	AudioSettings.BUS_MUSIC: %MusicSlider as HSlider,
	AudioSettings.BUS_UI: %UISlider as HSlider,
}
@onready var _serious_mode_check: CheckBox = %SeriousModeCheck
@onready var _language_button: Button = %LanguageButton
@onready var _window_button: Button = %WindowButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_apply_font_sizes()
	for bus_name: StringName in _sliders:
		(_sliders[bus_name] as HSlider).value_changed.connect(_on_volume_changed.bind(bus_name))
	_serious_mode_check.toggled.connect(_on_serious_mode_toggled)
	_language_button.pressed.connect(_on_language_pressed)
	_window_button.pressed.connect(_on_window_toggled)
	_back_button.pressed.connect(close)


func _apply_font_sizes() -> void:
	FontSettings.apply($OptionsTitle, FontSettings.ui_subtitle)
	for label_name: StringName in [&"MasterLabel", &"SFXLabel", &"MusicLabel", &"UILabel"]:
		FontSettings.apply(get_node(NodePath(label_name)), FontSettings.ui_body)
	FontSettings.apply(_serious_mode_check, FontSettings.ui_body)
	FontSettings.apply(_language_button, FontSettings.ui_button)
	FontSettings.apply(_window_button, FontSettings.ui_button)
	FontSettings.apply(_back_button, FontSettings.ui_button)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_sync_sliders()
	_sync_window_label()
	_sync_language_label()
	_serious_mode_check.button_pressed = GameSettings.serious_mode
	show()
	_back_button.grab_focus()


func close() -> void:
	AudioSettings.save_settings()
	GameSettings.save_settings()
	hide()
	closed.emit()


func _sync_sliders() -> void:
	for bus_name: StringName in _sliders:
		(_sliders[bus_name] as HSlider).value = AudioSettings.get_bus_volume_percent(bus_name)


func _sync_window_label() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	_window_button.text = "OPTIONS_WINDOW_FULLSCREEN" if is_fullscreen else "OPTIONS_WINDOW_WINDOWED"


func _on_volume_changed(value: float, bus_name: StringName) -> void:
	AudioSettings.apply_bus_volume(bus_name, value)


func _on_serious_mode_toggled(enabled: bool) -> void:
	GameSettings.serious_mode = enabled


func _on_language_pressed() -> void:
	LocaleManager.cycle_locale()
	_sync_language_label()
	_sync_window_label()


func _sync_language_label() -> void:
	var label: String = LocaleManager.LOCALE_LABELS.get(LocaleManager.get_locale(), "")
	_language_button.text = "%s: %s" % [tr("OPTIONS_LANGUAGE"), label]


func _on_window_toggled() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_sync_window_label()
