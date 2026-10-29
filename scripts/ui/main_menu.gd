class_name MainMenu
extends Control

const MENU_MUSIC := preload("res://audio/music/menu-music.ogg")

const CREDITS_SCENE := preload("res://scenes/ui/credits.tscn")
@onready var _credits_button: Button = %CreditsButton
var _credits: CreditsScreen

## Scene opened by the Play button (the level selector).
@export_file("*.tscn") var level_select_scene_path: String = "res://scenes/ui/level_select.tscn"

@onready var _logo: TextureRect = %LogoTexture
@onready var _menu_box: Control = %MenuBox
@onready var _play_button: Button = %PlayButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _options_menu: OptionsMenu = %OptionsMenu


func _ready() -> void:
	_apply_font_sizes()
	_play_button.pressed.connect(_on_play_pressed)
	_options_button.pressed.connect(_open_options)
	_quit_button.pressed.connect(_on_quit_pressed)
	_options_menu.closed.connect(_on_options_closed)
	_credits_button.pressed.connect(_open_credits)
	FontSettings.apply(_credits_button, FontSettings.ui_button)

	_options_menu.visible = false
	_menu_box.visible = true
	_play_button.grab_focus()
	MusicManager.play_music(MENU_MUSIC)


func _apply_font_sizes() -> void:
	FontSettings.apply(_play_button, FontSettings.ui_button)
	FontSettings.apply(_options_button, FontSettings.ui_button)
	FontSettings.apply(_quit_button, FontSettings.ui_button)


func _on_play_pressed() -> void:
	SceneLoader.go_to(get_tree(), level_select_scene_path)


func _open_options() -> void:
	_logo.hide()
	_menu_box.hide()
	_options_menu.open()


func _on_options_closed() -> void:
	_logo.show()
	_menu_box.show()
	_options_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _open_credits() -> void:
	_credits = CREDITS_SCENE.instantiate() as CreditsScreen
	_credits.closed.connect(_on_credits_closed)
	_logo.hide()
	_menu_box.hide()
	add_child(_credits)


func _on_credits_closed() -> void:
	_credits.queue_free()
	_logo.show()
	_menu_box.show()
	_credits_button.grab_focus()
