extends Node

signal serious_mode_changed(enabled: bool)

const SETTINGS_PATH := "user://game_settings.cfg"
const SETTINGS_SECTION := "game"

var serious_mode: bool = false:
	set(value):
		serious_mode = value
		serious_mode_changed.emit(value)


func _ready() -> void:
	_load_settings()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, "serious_mode", serious_mode)
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("GameSettings: failed to save settings (error %d)." % err)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	serious_mode = config.get_value(SETTINGS_SECTION, "serious_mode", false)
