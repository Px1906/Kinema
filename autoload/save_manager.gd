extends Node
## Persiste o progresso do jogador em um arquivo local JSON.

signal save_completed
signal save_failed(error: Error)
signal load_failed(error: Error)
signal delete_failed(error: Error)

const SAVE_PATH: String = "user://kinema_save.json"
const TEMP_SAVE_PATH: String = "user://kinema_save.json.tmp"
const CURRENT_VERSION: int = 1


func save_progress(progress: Dictionary) -> bool:
	var payload: Dictionary = {
		"version": CURRENT_VERSION,
		"progress": progress,
	}
	var file: FileAccess = FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var error: Error = FileAccess.get_open_error()
		save_failed.emit(error)
		push_error("Nao foi possivel abrir o arquivo temporario de save: %s" % error_string(error))
		return false

	var write_succeeded: bool = file.store_string(JSON.stringify(payload, "\t"))
	var write_error: Error = file.get_error()
	file.close()
	if not write_succeeded or write_error != OK:
		var error: Error = write_error if write_error != OK else ERR_FILE_CANT_WRITE
		_remove_temporary_save()
		save_failed.emit(error)
		push_error("Nao foi possivel escrever o arquivo de save: %s" % error_string(error))
		return false

	var rename_error: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(TEMP_SAVE_PATH),
		ProjectSettings.globalize_path(SAVE_PATH)
	)
	if rename_error != OK:
		_remove_temporary_save()
		save_failed.emit(rename_error)
		push_error("Nao foi possivel substituir o arquivo de save: %s" % error_string(rename_error))
		return false

	save_completed.emit()
	return true


func load_progress() -> Dictionary:
	if not has_save():
		return {}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		var error: Error = FileAccess.get_open_error()
		_report_load_failure(error, "Nao foi possivel abrir o arquivo de save para leitura")
		return {}

	var content: String = file.get_as_text()
	var read_error: Error = file.get_error()
	file.close()
	if read_error != OK:
		_report_load_failure(read_error, "Nao foi possivel ler o arquivo de save")
		return {}

	var parsed: Variant = JSON.parse_string(content)
	if not parsed is Dictionary:
		_report_load_failure(ERR_PARSE_ERROR, "O arquivo de save possui um formato invalido")
		return {}

	var payload: Dictionary = parsed
	var version: int = int(payload.get("version", 0))
	if version > CURRENT_VERSION:
		_report_load_failure(ERR_FILE_UNRECOGNIZED, "O arquivo de save usa uma versao mais nova")
		return {}

	var migrated_payload: Dictionary = _migrate(payload, version)
	var progress: Variant = migrated_payload.get("progress", {})
	if not progress is Dictionary:
		_report_load_failure(ERR_INVALID_DATA, "O progresso salvo possui um formato invalido")
		return {}

	return progress


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func resume_game(tree: SceneTree) -> bool:
	var progress: Dictionary = load_progress()
	var level_path: String = progress.get("current_level", "")
	if level_path.is_empty() or not ResourceLoader.exists(level_path):
		return false
	tree.change_scene_to_file(level_path)
	return true


func delete_save() -> bool:
	if not has_save():
		return true

	var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if error != OK:
		delete_failed.emit(error)
		push_error("Nao foi possivel remover o arquivo de save: %s" % error_string(error))
		return false
	return true


func _remove_temporary_save() -> void:
	if FileAccess.file_exists(TEMP_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SAVE_PATH))


func _report_load_failure(error: Error, message: String) -> void:
	load_failed.emit(error)
	push_error("%s: %s" % [message, error_string(error)])


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