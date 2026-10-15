extends Node
## Persiste o progresso do jogador em um arquivo local JSON.

signal save_completed
signal save_failed(error: Error)

const SAVE_PATH: String = "user://kinema_save.json"
const CURRENT_VERSION: int = 1


func save_progress(progress: Dictionary) -> bool:
	var payload: Dictionary = {
		"version": CURRENT_VERSION,
		"progress": progress,
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var error: Error = FileAccess.get_open_error()
		save_failed.emit(error)
		push_error("Nao foi possivel abrir o arquivo de save: %s" % error)
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	save_completed.emit()
	return true


func load_progress() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Nao foi possivel abrir o arquivo de save para leitura.")
		return {}

	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	if not parsed is Dictionary:
		push_error("O arquivo de save possui um formato invalido.")
		return {}

	var payload: Dictionary = parsed
	var version: int = int(payload.get("version", 0))
	if version > CURRENT_VERSION:
		push_error("O arquivo de save usa uma versao mais nova.")
		return {}

	return _migrate(payload, version).get("progress", {})


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> bool:
	if not has_save():
		return true

	var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if error != OK:
		push_error("Nao foi possivel remover o arquivo de save: %s" % error)
		return false
	return true


func _migrate(payload: Dictionary, version: int) -> Dictionary:
	var migrated: Dictionary = payload.duplicate(true)
	var current_version: int = version
	while current_version < CURRENT_VERSION:
		match current_version:
			0:
				migrated["progress"] = migrated.get("progress", {})
		current_version += 1
	migrated["version"] = CURRENT_VERSION
	return migrated