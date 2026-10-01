extends SceneTree
## Carrega todos os .gd do projeto e falha (exit 1) se algum não compilar.
## Uso: godot --headless --path . --script tools/check_scripts.gd

const SKIP_DIRS := ["addons", ".godot", ".git"]


func _initialize() -> void:
	var failed: Array[String] = []
	var total := 0
	for path in _find_scripts("res://"):
		total += 1
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			failed.append(path)
	print("Scripts checados: %d | com erro: %d" % [total, failed.size()])
	for path in failed:
		printerr("FALHOU: " + path)
	quit(1 if not failed.is_empty() else 0)


func _find_scripts(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub in dir.get_directories():
		if sub in SKIP_DIRS:
			continue
		found.append_array(_find_scripts(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.ends_with(".gd"):
			found.append(dir_path.path_join(file))
	return found
