class_name TutorialPopup
extends CanvasLayer

const ANIM_DURATION := 0.25

var _tween: Tween

@onready var _panel: PanelContainer = %Panel
@onready var _label: RichTextLabel = %Label
@onready var _sprite: TextureRect = %Sprite
@onready var _anim_player: AnimatedSprite2D = %AnimPlayer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	_connect_zones.call_deferred()


func _connect_zones() -> void:
	for node: Node in get_tree().get_nodes_in_group(TutorialPopupZone.GROUP):
		var zone := node as TutorialPopupZone
		if zone == null:
			continue
		zone.popup_requested.connect(show_popup)
		zone.popup_dismissed.connect(hide_popup)


func show_popup(data: TutorialPopupData) -> void:
	_label.text = data.text

	var is_anim := data.mode == TutorialPopupData.PopupMode.ANIMATION
	_sprite.visible = not is_anim and data.sprite != null
	_anim_player.visible = is_anim and data.animation_frames != null

	if data.sprite != null:
		_sprite.texture = data.sprite
	if data.animation_frames != null:
		_anim_player.sprite_frames = data.animation_frames
		_anim_player.animation = data.animation_name
		_anim_player.play()

	_animate_in()


func hide_popup() -> void:
	_animate_out()


func _animate_in() -> void:
	_kill_tween()
	visible = true
	_panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, ANIM_DURATION)


func _animate_out() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 0.0, ANIM_DURATION)
	_tween.tween_callback(_on_hidden)


func _on_hidden() -> void:
	visible = false
	_anim_player.stop()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
