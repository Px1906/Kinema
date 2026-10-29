class_name AnimatedStyleButton
extends Button
## Button com fundo animado via StyleBoxTexture.
## Usado para botões retangulares (grande, médio, pequeno) com texto por cima.

@export var normal_frames: Array[Texture2D] = []
@export var pressed_frame: Texture2D
@export var animation_fps: float = 2.0
@export var texture_margin: float = 20.0

var _current_frame := 0
var _timer := 0.0
var _normal_stylebox: StyleBoxTexture
var _pressed_stylebox: StyleBoxTexture


func _ready() -> void:
	_normal_stylebox = _create_stylebox(null)
	_pressed_stylebox = _create_stylebox(pressed_frame)

	if not normal_frames.is_empty():
		_normal_stylebox.texture = normal_frames[0]

	add_theme_stylebox_override("normal", _normal_stylebox)
	add_theme_stylebox_override("hover", _normal_stylebox)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	if pressed_frame != null:
		add_theme_stylebox_override("pressed", _pressed_stylebox)

	add_theme_stylebox_override("disabled", _normal_stylebox)

	add_theme_color_override("font_color", Color.BLACK)
	add_theme_color_override("font_hover_color", Color.BLACK)
	add_theme_color_override("font_pressed_color", Color(0.2, 0.2, 0.2))
	add_theme_color_override("font_focus_color", Color.BLACK)
	add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.55))

	set_process(normal_frames.size() > 1)


func _process(delta: float) -> void:
	_timer += delta
	if _timer < 1.0 / animation_fps:
		return
	_timer -= 1.0 / animation_fps
	_current_frame = (_current_frame + 1) % normal_frames.size()
	_normal_stylebox.texture = normal_frames[_current_frame]


func reapply_styleboxes() -> void:
	add_theme_stylebox_override("normal", _normal_stylebox)
	add_theme_stylebox_override("hover", _normal_stylebox)
	add_theme_stylebox_override("disabled", _normal_stylebox)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if pressed_frame != null:
		add_theme_stylebox_override("pressed", _pressed_stylebox)


func _create_stylebox(tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = texture_margin
	sb.texture_margin_top = texture_margin
	sb.texture_margin_right = texture_margin
	sb.texture_margin_bottom = texture_margin
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return sb
