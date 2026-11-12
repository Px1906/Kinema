class_name CreditsScreen
extends Control
## Tela de créditos (RF30): integrantes da equipe e a função de cada um.
## Cena própria: o botão Credits do MainMenu troca para ela, e Voltar/Esc trocam de
## volta para main_menu_scene_path.
## O conteúdo vem de CREDITS_PATH, então trocar nomes e funções não exige mexer na
## cena nem neste script. As cores vêm do tema global.

const CREDITS_PATH := "res://resources/credits.json"
## Largura de cada cartão: com o conteúdo em ~1126 px e h_separation 20 cabem 3 por linha.
const MEMBER_CARD_WIDTH := 360.0
## Fontes maiores que as do resto da UI: a tela só tem título, nomes e funções.
const TITLE_FONT_SIZE := 76
const MEMBERS_TITLE_FONT_SIZE := 48
const MEMBER_ROLE_COLOR := Color(0.25, 0.25, 0.3)

## Scene opened by the Back button and by Esc.
@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/ui/main_menu.tscn"

@onready var _title_label: Label = %TitleLabel
@onready var _members_title: Label = %MembersTitle
@onready var _members_box: HFlowContainer = %MembersBox
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_apply_font_sizes()
	_back_button.pressed.connect(close)
	_fill(_load_credits())
	_back_button.grab_focus()


func _apply_font_sizes() -> void:
	FontSettings.apply(_title_label, TITLE_FONT_SIZE)
	FontSettings.apply(_members_title, MEMBERS_TITLE_FONT_SIZE)
	FontSettings.apply(_back_button, FontSettings.ui_button)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	SceneLoader.go_to(get_tree(), main_menu_scene_path)


func _fill(data: Dictionary) -> void:
	for child in _members_box.get_children():
		_members_box.remove_child(child)
		child.queue_free()

	var members: Array = data.get("members", [])
	for member: Variant in members:
		if member is Dictionary:
			_members_box.add_child(_make_member_card(member))
	_members_title.visible = _members_box.get_child_count() > 0


## Cartão de um membro: nome em cima e, se houver, a função embaixo.
func _make_member_card(member: Dictionary) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.custom_minimum_size.x = MEMBER_CARD_WIDTH
	card.add_theme_constant_override("separation", 4)

	var name_label := Label.new()
	name_label.text = member.get("name", "")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	FontSettings.apply(name_label, FontSettings.ui_subtitle)
	card.add_child(name_label)

	var role: String = member.get("role", "")
	if not role.is_empty():
		var role_label := Label.new()
		role_label.text = role
		role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		role_label.add_theme_color_override("font_color", MEMBER_ROLE_COLOR)
		FontSettings.apply(role_label, FontSettings.popup)
		card.add_child(role_label)

	return card


func _load_credits() -> Dictionary:
	if not FileAccess.file_exists(CREDITS_PATH):
		push_error("CreditsScreen: arquivo não encontrado: %s" % CREDITS_PATH)
		return {}

	var file := FileAccess.open(CREDITS_PATH, FileAccess.READ)
	if file == null:
		push_error("CreditsScreen: falha ao abrir: %s" % CREDITS_PATH)
		return {}

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("CreditsScreen: erro ao ler JSON: %s" % json.get_error_message())
		return {}

	if not json.data is Dictionary:
		push_error("CreditsScreen: JSON raiz não é um objeto.")
		return {}

	return json.data
