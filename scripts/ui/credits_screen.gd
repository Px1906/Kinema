class_name CreditsScreen
extends Control
## Tela de créditos (RF30): contexto do projeto e integrantes da equipe.
## Abre como painel sobre o menu principal, igual ao OptionsMenu: o MainMenu instancia
## a cena, esconde o logo e o menu, e restaura tudo ao receber closed.
## O conteúdo vem de CREDITS_PATH, então trocar nomes e funções não exige mexer na
## cena nem neste script. As cores vêm do tema global.

signal closed

const CREDITS_PATH := "res://resources/credits.json"

@onready var _title_label: Label = %TitleLabel
@onready var _context_label: Label = %ContextLabel
@onready var _members_title: Label = %MembersTitle
@onready var _members_box: VBoxContainer = %MembersBox
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_apply_font_sizes()
	_back_button.pressed.connect(close)
	_fill(_load_credits())
	_back_button.grab_focus()


func _apply_font_sizes() -> void:
	FontSettings.apply(_title_label, FontSettings.ui_title)
	FontSettings.apply(_context_label, FontSettings.ui_body)
	FontSettings.apply(_members_title, FontSettings.ui_subtitle)
	FontSettings.apply(_back_button, FontSettings.ui_button)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	closed.emit()


func _fill(data: Dictionary) -> void:
	_context_label.text = data.get("context", "")
	_context_label.visible = not _context_label.text.is_empty()

	for child in _members_box.get_children():
		_members_box.remove_child(child)
		child.queue_free()

	var members: Array = data.get("members", [])
	for member: Variant in members:
		if member is Dictionary:
			_members_box.add_child(_make_member_label(member))


func _make_member_label(member: Dictionary) -> Label:
	var member_name: String = member.get("name", "")
	var role: String = member.get("role", "")

	var label := Label.new()
	label.text = member_name if role.is_empty() else "%s — %s" % [member_name, role]
	FontSettings.apply(label, FontSettings.ui_body)
	return label


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
