class_name TutorialPopupData
extends Resource
## Conteúdo de um popup de tutorial. Os popups da fase ficam em POPUPS_PATH, um por id:
## a zona pede o seu com from_json(), e o arquivo é lido uma vez só.

enum PopupMode { TEXT_AND_SPRITE, ANIMATION }

const POPUPS_PATH := "res://resources/tutorial_popups.json"
const MODE_NAMES := {
	"text_and_sprite": PopupMode.TEXT_AND_SPRITE,
	"animation": PopupMode.ANIMATION,
}

static var _entries: Dictionary = {}
static var _entries_loaded := false

@export var mode: PopupMode = PopupMode.TEXT_AND_SPRITE
@export_multiline var text: String = ""
@export var sprite: Texture2D
@export var animation_frames: SpriteFrames
@export var animation_name: StringName = &"default"


## Monta o popup do id a partir do JSON. Retorna null se o id não existir.
## sprite e animation_frames são caminhos res:// (vazio = sem imagem/animação);
## a animação é um SpriteFrames (.tres), já que o Godot não toca GIF direto.
static func from_json(id: String) -> TutorialPopupData:
	_load_entries()
	if not _entries.has(id):
		push_error("TutorialPopupData: popup '%s' não existe em %s." % [id, POPUPS_PATH])
		return null

	var entry: Dictionary = _entries[id]
	var data := TutorialPopupData.new()
	var mode_name: String = entry.get("mode", "text_and_sprite")
	if not MODE_NAMES.has(mode_name):
		push_warning("TutorialPopupData: modo '%s' inválido em '%s'." % [mode_name, id])
	data.mode = MODE_NAMES.get(mode_name, PopupMode.TEXT_AND_SPRITE)
	data.text = entry.get("text", "")
	data.sprite = _load_optional(entry.get("sprite", ""), id) as Texture2D
	data.animation_frames = _load_optional(entry.get("animation_frames", ""), id) as SpriteFrames
	data.animation_name = StringName(entry.get("animation_name", "default"))
	return data


static func _load_optional(path: String, id: String) -> Resource:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_error("TutorialPopupData: arquivo '%s' do popup '%s' não existe." % [path, id])
		return null
	return load(path)


static func _load_entries() -> void:
	if _entries_loaded:
		return
	_entries_loaded = true

	var file := FileAccess.open(POPUPS_PATH, FileAccess.READ)
	if file == null:
		push_error("TutorialPopupData: falha ao abrir: %s" % POPUPS_PATH)
		return

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("TutorialPopupData: erro ao ler JSON: %s" % json.get_error_message())
		return

	if not json.data is Dictionary:
		push_error("TutorialPopupData: JSON raiz não é um objeto (id -> popup).")
		return

	_entries = json.data
