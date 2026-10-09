extends Control
class_name MouseControl

@export var player: Player

@export_category("Launch Vector")
@export var invert_direction: bool = false
@export var arrow_speed_factor: float = 3.0
@export var max_speed: float = Player.MAX_SPEED
@export var min_distance: float = 5.0

@export_category("Visual")
@export var show_area: bool = true
@export var area_color := Color(1, 1, 1, 0.08)
@export var vector_color := Color("#f87171")

var _aiming := false
var _start := Vector2.ZERO
var _current := Vector2.ZERO


func _ready() -> void:
	if player == null:
		push_warning("MouseControl: fill in the player field in the editor")
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and player.pode_mirar():
			_aiming = true
			_start = event.position
			_current = event.position
		else:
			_aiming = false
		queue_redraw()
		accept_event()

	elif event is InputEventMouseMotion and _aiming:
		if player.state != Player.State.PREPARANDO:
			_aiming = false
		else:
			_current = event.position
			_apply_vector()
		queue_redraw()
		accept_event()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and _aiming:
			player.launch()


func _apply_vector() -> void:
	var v := _current - _start
	if invert_direction:
		v = -v
	if v.length() < min_distance:
		return
	var angle := rad_to_deg(atan2(-v.y, v.x))
	
	if not player.inicio_suspenso:
		if clampf(angle, -90, 0) == angle:
			angle = 0
		if clampf(angle, -Player.MAX_ANGLE, -90) == angle:
			angle = Player.MAX_ANGLE
	
	var speed := minf(v.length() * arrow_speed_factor, max_speed)
	player.set_launch_parameters(speed, angle)


func _draw() -> void:
	if show_area:
		draw_rect(Rect2(Vector2.ZERO, size), area_color)
		draw_rect(Rect2(Vector2.ZERO, size), vector_color, false, 1.0)
	if _aiming:
		draw_line(_start, _current, vector_color, 2.0)
		draw_circle(_start, 4.0, vector_color)
