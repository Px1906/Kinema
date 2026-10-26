class_name TutorialPopupData
extends Resource

enum PopupMode { TEXT_AND_SPRITE, ANIMATION }

@export var mode: PopupMode = PopupMode.TEXT_AND_SPRITE
@export_multiline var text: String = ""
@export var sprite: Texture2D
@export var animation_frames: SpriteFrames
@export var animation_name: StringName = &"default"
