class_name LevelSelect
extends Control

const CARD_SIZE := Vector2(220.0, 140.0)
const TEXT_COLOR := Color("#0f172a")

## Scene opened by the Back button and by Esc.
@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/ui/main_menu.tscn"

## One card is created per scene, in this order. Edit the list in the Inspector.
@export_file("*.tscn") var level_paths: PackedStringArray = PackedStringArray([
	"res://scenes/levels/fase_tutorial.tscn",
])
## Optional display names, in the same order as level_paths.
## Missing or empty names fall back to the scene file name.
@export var level_titles: PackedStringArray = PackedStringArray([
	"Tutorial",
])
## Optional preview images, in the same order as level_paths.
## Levels without an image show their number inside the card.
@export var level_thumbnails: Array[Texture2D] = []
## How many cards are visible at once. The arrows change the page.
@export_range(1, 8, 1) var levels_per_page: int = 3

var _page := 0
var _card_buttons: Array[Button] = []

@onready var _cards_box: HBoxContainer = %CardsBox
@onready var _previous_button: Button = %PreviousButton
@onready var _next_button: Button = %NextButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(_go_back)
	_previous_button.pressed.connect(_change_page.bind(-1))
	_next_button.pressed.connect(_change_page.bind(1))
	_show_page()
	_focus_first_card()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()


func _page_count() -> int:
	var per_page := maxi(levels_per_page, 1)
	return maxi(ceili(float(level_paths.size()) / per_page), 1)


func _show_page() -> void:
	for child in _cards_box.get_children():
		_cards_box.remove_child(child)
		child.queue_free()
	_card_buttons.clear()

	if level_paths.is_empty():
		_cards_box.add_child(_make_empty_label())
	else:
		var per_page := maxi(levels_per_page, 1)
		var first := _page * per_page
		var last := mini(first + per_page, level_paths.size())
		for index in range(first, last):
			_cards_box.add_child(_make_card(index))

	# The arrows only matter when there is more than one page.
	var has_several_pages := _page_count() > 1
	_previous_button.visible = has_several_pages
	_next_button.visible = has_several_pages
	_previous_button.disabled = _page <= 0
	_next_button.disabled = _page >= _page_count() - 1


func _make_card(index: int) -> Control:
	var path := level_paths[index]

	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)

	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	var thumbnail: Texture2D = level_thumbnails[index] if index < level_thumbnails.size() else null
	if thumbnail != null:
		button.icon = thumbnail
		button.expand_icon = true
	else:
		button.text = str(index + 1)
		button.add_theme_font_size_override("font_size", 48)
	if ResourceLoader.exists(path):
		button.pressed.connect(_start_level.bind(path))
	else:
		button.disabled = true
		button.tooltip_text = "Cena não encontrada: %s" % path
	card.add_child(button)
	_card_buttons.append(button)

	var label := Label.new()
	label.text = _get_level_title(index)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	# The default label color is light, so it needs a dark color over the paper.
	label.add_theme_color_override("font_color", TEXT_COLOR)
	card.add_child(label)
	return card


func _make_empty_label() -> Label:
	var label := Label.new()
	label.text = "Nenhuma fase configurada."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TEXT_COLOR)
	return label


func _get_level_title(index: int) -> String:
	if index < level_titles.size() and not level_titles[index].is_empty():
		return level_titles[index]
	return level_paths[index].get_file().get_basename().capitalize()


func _change_page(step: int) -> void:
	_page = clampi(_page + step, 0, _page_count() - 1)
	_show_page()
	# A disabled arrow cannot keep the focus, so move it to the first card.
	if (step > 0 and _next_button.disabled) or (step < 0 and _previous_button.disabled):
		_focus_first_card()


func _focus_first_card() -> void:
	if _card_buttons.is_empty():
		_back_button.grab_focus()
	else:
		_card_buttons[0].grab_focus()


func _start_level(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _go_back() -> void:
	if not ResourceLoader.exists(main_menu_scene_path):
		push_warning("LevelSelect: main_menu_scene_path is not a valid scene: '%s'" % main_menu_scene_path)
		return

	get_tree().change_scene_to_file(main_menu_scene_path)
