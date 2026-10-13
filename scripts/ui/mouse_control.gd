class_name MouseControl
extends Control

@export var player: Player

@export_category("Launch Vector")
@export var invert_direction: bool = false
@export var speed_factor: float = 3.0
@export var max_speed: float = Player.MAX_SPEED
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
	if player == null:
		return

	player.state_changed.connect(_on_player_state_changed)
	_update_interaction_area()
	_update_mouse_filter()


func _update_mouse_filter() -> void:
	mouse_filter = (
		Control.MOUSE_FILTER_STOP
		if player.can_launch()
		else Control.MOUSE_FILTER_IGNORE
	)


func _update_interaction_area() -> void:
	var diameter := interaction_radius * 2.0
	size = Vector2.ONE * diameter
	global_position = player.global_position - Vector2.ONE * interaction_radius


func _gui_input(event: InputEvent) -> void:
	if player == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and player.can_launch():
			_dragging = true
			_start = size / 2.0
			_current = event.position
		else:
			_dragging = false
		queue_redraw()
		accept_event()

	elif event is InputEventMouseMotion and _dragging:
		if not player.can_launch():
			_dragging = false
		else:
			_current = event.position
			_apply_launch_vector()
		queue_redraw()
		accept_event()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and player.can_launch() and _dragging:
			player.launch()


func _apply_launch_vector() -> void:
	var vector := _current - _start
	if invert_direction:
		vector = -vector
	if vector.length() < min_distance:
		return

	var angle := rad_to_deg(atan2(-vector.y, vector.x))
	angle = player.clamp_launch_angle(angle)
	var speed := minf(vector.length() * speed_factor, max_speed)
	player.set_launch_parameters(speed, angle)


func _on_player_state_changed(_new_state) -> void:
	_dragging = false
	_update_mouse_filter()
	queue_redraw()


func _draw() -> void:
	if show_area:
		draw_rect(Rect2(Vector2.ZERO, size), area_color)
		draw_rect(Rect2(Vector2.ZERO, size), vector_color, false, 1.0)
	if _dragging:
		draw_line(_start, _current, vector_color, 2.0)
		draw_circle(_start, 4.0, vector_color)
