class_name Credits
extends Control

const TEXT_COLOR := Color("#0f172a")
const MEMBER_FONT_SIZE := 22

## Scene opened by the Back button and by Esc.
@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/ui/main_menu.tscn"

## About the project. Edit the text in the Inspector.
@export_multiline var project_context: String = (
	"Kinema é um jogo educacional 2D de cinemática, feito em Godot 4. "
	+ "O jogador lança uma bola por fases e usa velocidade, ângulo e energia "
	+ "para chegar ao objetivo."
)
## One line per member, for example "Name — role". Edit the list in the Inspector.
@export var members: PackedStringArray = PackedStringArray([
	"Sérgio de Paiva — Função",
	"Cleyton Ramsay — Função",
	"Mário Bernardo — Função",
	"Gustavo Mendonça — Função",
])

@onready var _context_label: Label = %ContextLabel
@onready var _members_title: Label = %MembersTitle
@onready var _members_box: VBoxContainer = %MembersBox
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_context_label.text = project_context
	_fill_members()
	_back_button.pressed.connect(_go_back)
	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()


func _fill_members() -> void:
	_members_title.visible = not members.is_empty()
	for member in members:
		var label := Label.new()
		label.text = member
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", MEMBER_FONT_SIZE)
		# The default label color is light, so it needs a dark color over the paper.
		label.add_theme_color_override("font_color", TEXT_COLOR)
		_members_box.add_child(label)


func _go_back() -> void:
	SceneLoader.go_to(get_tree(), main_menu_scene_path)
