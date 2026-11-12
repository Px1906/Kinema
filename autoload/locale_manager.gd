extends Node

signal locale_changed(locale: String)

const LOCALES: Array[String] = ["pt", "en", "es"]
const LOCALE_LABELS: Dictionary = {
	"pt": "Português",
	"en": "English",
	"es": "Español",
}


func _ready() -> void:
	var saved_locale: String = GameSettings.get_locale()
	if saved_locale.is_empty():
		saved_locale = "pt"
	set_locale(saved_locale)


func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	GameSettings.set_locale(locale)
	locale_changed.emit(locale)


func get_locale() -> String:
	return TranslationServer.get_locale()


func cycle_locale() -> String:
	var current := get_locale()
	var index := LOCALES.find(current)
	var next_index := (index + 1) % LOCALES.size()
	var next_locale := LOCALES[next_index]
	set_locale(next_locale)
	return next_locale


