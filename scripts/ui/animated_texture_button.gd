class_name AnimatedTextureButton
extends TextureButton
## TextureButton que cicla frames automaticamente como animação idle.
## Usado para botões circulares com ícone (play, pause, recomeçar, cancelar).

@export var frames: Array[Texture2D] = []
@export var pressed_frame: Texture2D
@export var animation_fps: float = 2.0

var _current_frame := 0
var _timer := 0.0


func _ready() -> void:
	if not frames.is_empty():
		texture_normal = frames[0]
	if pressed_frame != null:
		texture_pressed = pressed_frame
	set_process(frames.size() > 1)


func _process(delta: float) -> void:
	_timer += delta
	if _timer < 1.0 / animation_fps:
		return
	_timer -= 1.0 / animation_fps
	_current_frame = (_current_frame + 1) % frames.size()
	texture_normal = frames[_current_frame]
