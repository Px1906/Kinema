class_name QteReaction
extends Resource

@export var sprite_frames: SpriteFrames
@export var animation_name: StringName = &"default"
@export var sound: AudioStream
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var volume_db: float = 0.0
@export var start_scale: float = 0.8
@export var end_scale: float = 4.0
