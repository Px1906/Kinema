class_name OptionsMenu
extends PanelContainer

signal closed

const BUS_MASTER := &"Master"
const BUS_SFX := &"SFX"
const BUS_MUSIC := &"Music"
const BUS_UI := &"UI"
const SETTINGS_PATH := "user://audio_settings.cfg"
const SETTINGS_SECTION := "audio"

@onready var _master_slider: HSlider = %MasterSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _ui_slider: HSlider = %UISlider
@onready var _window_button: Button = %WindowButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_load_settings()
	_master_slider.value_changed.connect(_on_master_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_ui_slider.value_changed.connect(_on_ui_changed)
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
	hide()
	closed.emit()


func _sync_sliders() -> void:
	_master_slider.value = _get_bus_volume_percent(BUS_MASTER)
	_sfx_slider.value = _get_bus_volume_percent(BUS_SFX)
	_music_slider.value = _get_bus_volume_percent(BUS_MUSIC)
	_ui_slider.value = _get_bus_volume_percent(BUS_UI)


func _sync_window_label() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	_window_button.text = "Janela: Tela cheia" if is_fullscreen else "Janela: Modo janela"


func _on_master_changed(value: float) -> void:
	_set_bus_volume(BUS_MASTER, value)
	_save_settings()


func _on_sfx_changed(value: float) -> void:
	_set_bus_volume(BUS_SFX, value)
	_save_settings()


func _on_music_changed(value: float) -> void:
	_set_bus_volume(BUS_MUSIC, value)
	_save_settings()


func _on_ui_changed(value: float) -> void:
	_set_bus_volume(BUS_UI, value)
	_save_settings()


func _on_window_toggled() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_sync_window_label()


func _set_bus_volume(bus_name: StringName, percent: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if percent <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(percent / 100.0))


func _get_bus_volume_percent(bus_name: StringName) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return 100.0
	if AudioServer.is_bus_mute(idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) * 100.0


func _save_settings() -> void:
	var config := ConfigFile.new()
	for bus_name: StringName in [BUS_MASTER, BUS_SFX, BUS_MUSIC, BUS_UI]:
		config.set_value(SETTINGS_SECTION, String(bus_name), _get_bus_volume_percent(bus_name))
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for bus_name: StringName in [BUS_MASTER, BUS_SFX, BUS_MUSIC, BUS_UI]:
		var percent: float = config.get_value(SETTINGS_SECTION, String(bus_name), 100.0)
		_set_bus_volume(bus_name, percent)
