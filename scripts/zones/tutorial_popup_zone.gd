class_name TutorialPopupZone
extends Area2D

const GROUP := &"tutorial_popup_zone"
const ANIM_DURATION := 0.25
const EXIT_GRACE_FRAMES := 3

## Id do popup em resources/tutorial_popups.json (texto, imagem e animação).
@export var popup_id: String = ""
## Alternativa ao JSON: um TutorialPopupData montado no Inspector. Usado só sem popup_id.
@export var popup_data: TutorialPopupData

var _player_inside := false
var _tracked_player: Player = null
var _tween: Tween
var _exit_frames := 0

@onready var _panel: Control = %Panel
@onready var _label: RichTextLabel = %Label
@onready var _sprite: TextureRect = %Sprite
@onready var _anim_player: AnimatedSprite2D = %AnimPlayer
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _display_anchor: Marker2D = $DisplayAnchor


func _ready() -> void:
	add_to_group(GROUP)
	if not popup_id.is_empty():
		popup_data = TutorialPopupData.from_json(popup_id)
	body_entered.connect(_on_body_entered)
	FontSettings.apply(_label, FontSettings.popup)
	_panel.visible = false
	var anchor_pos := _display_anchor.position
	if anchor_pos != Vector2.ZERO:
		_panel.offset_left += anchor_pos.x
		_panel.offset_right += anchor_pos.x
		_panel.offset_top += anchor_pos.y
		_panel.offset_bottom += anchor_pos.y
	_find_player.call_deferred()


func _find_player() -> void:
	if _tracked_player != null:
		return
	_tracked_player = _get_player_in_tree()


func _get_player_in_tree() -> Player:
	var root := get_tree().current_scene
	if root == null:
		return null
	return root.find_child("Player", true, false) as Player


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_tracked_player = body as Player


func _physics_process(_delta: float) -> void:
	if _tracked_player == null or not is_instance_valid(_tracked_player):
		return
	if popup_data == null:
		return

	var in_range := _is_player_in_range()

	if in_range and not _player_inside:
		_player_inside = true
		_exit_frames = 0
		_show_popup()
	elif in_range:
		_exit_frames = 0
	elif _player_inside:
		_exit_frames += 1
		if _exit_frames >= EXIT_GRACE_FRAMES:
			_player_inside = false
			_exit_frames = 0
			_hide_popup()


func _is_player_in_range() -> bool:
	var local_pos := to_local(_tracked_player.global_position)
	var shape := _collision_shape.shape as RectangleShape2D
	var half := shape.size / 2.0
	return absf(local_pos.x) <= half.x and absf(local_pos.y) <= half.y


func _show_popup() -> void:
	_label.text = popup_data.text

	var is_anim := popup_data.mode == TutorialPopupData.PopupMode.ANIMATION
	_sprite.visible = not is_anim and popup_data.sprite != null
	_anim_player.visible = is_anim and popup_data.animation_frames != null

	if popup_data.sprite != null:
		_sprite.texture = popup_data.sprite
	if popup_data.animation_frames != null:
		_anim_player.sprite_frames = popup_data.animation_frames
		_anim_player.animation = popup_data.animation_name
		_anim_player.play()

	_kill_tween()
	_panel.visible = true
	_panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, ANIM_DURATION)


func _hide_popup() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 0.0, ANIM_DURATION)
	_tween.tween_callback(func() -> void:
		_panel.visible = false
		_anim_player.stop()
	)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
