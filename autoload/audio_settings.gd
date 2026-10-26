extends Node

const BUS_MASTER := &"Master"
const BUS_SFX := &"SFX"
const BUS_MUSIC := &"Music"
const BUS_UI := &"UI"
const BUSES: Array[StringName] = [BUS_MASTER, BUS_SFX, BUS_MUSIC, BUS_UI]
const SETTINGS_PATH := "user://audio_settings.cfg"
const SETTINGS_SECTION := "audio"


func _ready() -> void:
	_load_settings()


func apply_bus_volume(bus_name: StringName, percent: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if percent <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(percent / 100.0))


func get_bus_volume_percent(bus_name: StringName) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return 100.0
	if AudioServer.is_bus_mute(idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) * 100.0


func save_settings() -> void:
	var config := ConfigFile.new()
	for bus_name: StringName in BUSES:
		config.set_value(SETTINGS_SECTION, String(bus_name), get_bus_volume_percent(bus_name))
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("AudioSettings: failed to save settings (error %d)." % err)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for bus_name: StringName in BUSES:
		var percent: float = config.get_value(SETTINGS_SECTION, String(bus_name), 100.0)
		apply_bus_volume(bus_name, percent)
