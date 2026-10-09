class_name MouseControl
extends Control

@export var player: Player

@export_category("Launch Vector")
@export var invert_direction: bool = false
@export var speed_factor: float = 3.0
@export var max_speed: float = 1000.0
@export var min_distance: float = 5.0
@export_range(16.0, 512.0, 1.0) var interaction_radius: float = 96.0

@export_category("Visual")
@export var show_area: bool = false
@export var area_color := Color(1, 1, 1, 0.08)
@export var vector_color := Color("#f87171")

var _dragging := false
var _start := Vector2.ZERO
var _current := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_interaction_area()


func _process(_delta: float) -> void:
	if player == null:
		return

	var is_ready := player.is_ready()
	mouse_filter = Control.MOUSE_FILTER_STOP if is_ready else Control.MOUSE_FILTER_IGNORE
	if is_ready:
		_update_interaction_area()


func _update_interaction_area() -> void:
	var diameter := interaction_radius * 2.0
	size = Vector2.ONE * diameter
	position = player.global_position - Vector2.ONE * interaction_radius


func _gui_input(event: InputEvent) -> void:
	if player == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and player.is_ready():
			_dragging = true
			_start = size / 2.0
			_current = event.position
		else:
			_dragging = false
		queue_redraw()
		accept_event()

	elif event is InputEventMouseMotion and _dragging:
		if not player.is_ready():
			_dragging = false
		else:
			_current = event.position
			_apply_launch_vector()
		queue_redraw()
		accept_event()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and player.is_ready() and _dragging:
			player.launch()


func _apply_launch_vector() -> void:
	var vector := _current - _start
	if invert_direction:
		vector = -vector
	if vector.length() < min_distance:
		return

	var angle := rad_to_deg(atan2(-vector.y, vector.x))
	if angle < 0.0:
		angle += 360.0
	var speed := minf(vector.length() * speed_factor, max_speed)
	player.set_launch_parameters(speed, angle)


func _draw() -> void:
	if show_area:
		draw_rect(Rect2(Vector2.ZERO, size), area_color)
		draw_rect(Rect2(Vector2.ZERO, size), vector_color, false, 1.0)
	if _dragging:
		draw_line(_start, _current, vector_color, 2.0)
		draw_circle(_start, 4.0, vector_color)
