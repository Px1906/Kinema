class_name Rope
extends Node2D

signal activated
signal deactivated
signal player_entered(player: Player)
signal player_exited(player: Player)
signal player_attached(player: Player)
signal player_detached(player: Player)

const MIN_WIDTH := 1.0
const MAX_WIDTH := 32.0
const MIN_DETECTION_RADIUS := 1.0
const MAX_DETECTION_RADIUS := 2000.0
const DEFAULT_DETECTION_RADIUS := 160.0
const DEFAULT_ROPE_LENGTH := 160.0
const MIN_GRAVITY := 0.0
const MAX_GRAVITY := 3000.0
const DEFAULT_DIRECTION := Vector2.DOWN
const DOWN_ANGLE := PI / 2.0

@export_category("Rope")
var length: float = DEFAULT_ROPE_LENGTH
@export_range(MIN_WIDTH, MAX_WIDTH, 1.0) var width: float = 4.0:
	set(value):
		width = maxf(value, MIN_WIDTH)
		queue_redraw()
@export var rope_color := Color("#94a3b8")
@export_range(MIN_DETECTION_RADIUS, MAX_DETECTION_RADIUS, 1.0) var detection_radius: float = 160.0:
	set(value):
		detection_radius = maxf(value, MIN_DETECTION_RADIUS)
		_update_rope_length()
		if is_node_ready():
			_update_detection_shape()
			_update_area_animation_scale()
@export_range(MIN_GRAVITY, MAX_GRAVITY, 1.0) var gravity_acceleration: float = 980.0

var _active := false
var _direction := DEFAULT_DIRECTION
var _detected_player: Player
var _attached_player: Player
var _attached_player_was_frozen := false
var _pendulum_angle := 0.0
var _angular_velocity := 0.0
var _area_animation_base_scale := Vector2.ONE

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var area_animation: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_area_animation_base_scale = area_animation.scale
	_update_detection_shape()
	_update_area_animation_scale()
	area_animation.visible = true
	area_animation.play()
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_attached_player):
		_attached_player = null
		return

	var angular_acceleration := -gravity_acceleration / length * sin(_pendulum_angle)
	_angular_velocity += angular_acceleration * delta
	_pendulum_angle += _angular_velocity * delta
	_direction = Vector2.DOWN.rotated(_pendulum_angle)
	_attached_player.global_position = get_endpoint_global_position()
	_attached_player.linear_velocity = Vector2.ZERO
	_attached_player.angular_velocity = 0.0
	queue_redraw()


func activate_toward(target_global_position: Vector2) -> void:
	var target_direction := target_global_position - global_position
	if target_direction.is_zero_approx():
		return

	_direction = target_direction.normalized()
	_active = true
	activated.emit()
	queue_redraw()


func deactivate() -> void:
	if not _active:
		return

	_active = false
	deactivated.emit()
	queue_redraw()


func is_active() -> bool:
	return _active


func get_endpoint_global_position() -> Vector2:
	return global_position + _direction * length


func is_player_attached() -> bool:
	return _attached_player != null


func detach_player() -> void:
	if _attached_player == null:
		return

	var player := _attached_player
	_attached_player = null
	area_animation.visible = true
	player.set_stop_detection_enabled(true)
	player.freeze = _attached_player_was_frozen
	player.linear_velocity = _direction.rotated(PI / 2.0) * _angular_velocity * length
	_detected_player = null
	deactivate()
	player_detached.emit(player)


func _update_detection_shape() -> void:
	var circle := detection_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		detection_shape.shape = circle
	circle.radius = detection_radius


func _update_rope_length() -> void:
	length = detection_radius * DEFAULT_ROPE_LENGTH / DEFAULT_DETECTION_RADIUS


func _update_area_animation_scale() -> void:
	var scale_factor := detection_radius / DEFAULT_DETECTION_RADIUS
	area_animation.scale = _area_animation_base_scale * scale_factor


func _on_detection_area_body_entered(body: Node2D) -> void:
	if _attached_player != null or not body is Player:
		return

	var player := body as Player
	_detected_player = player
	call_deferred("_attach_player", player)


func _attach_player(player: Player) -> void:
	if not is_instance_valid(player) or _attached_player != null or _detected_player != player:
		return

	activate_toward(player.global_position)
	_attached_player_was_frozen = player.freeze
	_pendulum_angle = _direction.angle() - DOWN_ANGLE
	_angular_velocity = player.linear_velocity.dot(_direction.rotated(PI / 2.0)) / length
	_attached_player = player
	area_animation.visible = false
	player.set_stop_detection_enabled(false)
	player.freeze = true
	player.global_position = get_endpoint_global_position()
	player.linear_velocity = Vector2.ZERO
	player.angular_velocity = 0.0
	player_entered.emit(player)
	player_attached.emit(player)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body != _detected_player or _attached_player != null:
		return

	var player := _detected_player
	_detected_player = null
	deactivate()
	player_exited.emit(player)


func _draw() -> void:
	if not _active:
		return

	draw_line(Vector2.ZERO, _direction * length, rope_color, width, true)
