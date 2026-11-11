extends Node

const TRANSLATIONS_PATH := "res://translations/translations.csv"
const LOCALES: Array[String] = ["pt", "en", "es"]
const LOCALE_LABELS: Dictionary = {
	"pt": "Português",
	"en": "English",
	"es": "Español",
}


func _ready() -> void:
	_load_csv_translations()
	var saved_locale: String = GameSettings.get_locale()
	if saved_locale.is_empty():
		saved_locale = "pt"
	set_locale(saved_locale)


func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	GameSettings.set_locale(locale)


func get_locale() -> String:
	return TranslationServer.get_locale()


func cycle_locale() -> String:
	var current := get_locale()
	var index := LOCALES.find(current)
	var next_index := (index + 1) % LOCALES.size()
	var next_locale := LOCALES[next_index]
	set_locale(next_locale)
	return next_locale


func _load_csv_translations() -> void:
	var file := FileAccess.open(TRANSLATIONS_PATH, FileAccess.READ)
	if file == null:
		push_error("LocaleManager: failed to open %s" % TRANSLATIONS_PATH)
		return

	var header := file.get_csv_line()
	if header.size() < 2:
		push_error("LocaleManager: invalid CSV header.")
		return

	var translations: Array[Translation] = []
	for i in range(1, header.size()):
		var t := Translation.new()
		t.locale = header[i]
		translations.append(t)

	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() < 2 or line[0].is_empty():
			continue
		var key := line[0]
		for i in range(1, mini(line.size(), header.size())):
			var value := line[i].c_unescape()
			if not value.is_empty():
				translations[i - 1].add_message(key, value)

	for t in translations:
		TranslationServer.add_translation(t)
