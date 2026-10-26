class_name MainMenu
extends Control

const MENU_MUSIC := preload("res://audio/music/menu-music.ogg")

## Scene opened by the Play button (the level selector).
@export_file("*.tscn") var level_select_scene_path: String = "res://scenes/ui/level_select.tscn"

@onready var _menu_box: Control = %MenuBox
@onready var _play_button: Button = %PlayButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _options_menu: OptionsMenu = %OptionsMenu


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_options_button.pressed.connect(_open_options)
	_quit_button.pressed.connect(_on_quit_pressed)
	_options_menu.closed.connect(_on_options_closed)

	_options_menu.visible = false
	_menu_box.visible = true
	_play_button.grab_focus()
	MusicManager.play_music(MENU_MUSIC)


func _on_play_pressed() -> void:
	SceneLoader.go_to(get_tree(), level_select_scene_path)


func _open_options() -> void:
	_menu_box.visible = false
	_options_menu.open()


func _on_options_closed() -> void:
	_menu_box.visible = true
	_options_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
