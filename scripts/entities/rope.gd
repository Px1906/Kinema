extends Node2D
class_name Rope

const MIN_LENGTH := 1.0
const MAX_LENGTH := 2000.0
const MIN_WIDTH := 1.0
const MAX_WIDTH := 32.0
const MIN_DETECTION_RADIUS := 1.0
const MAX_DETECTION_RADIUS := 2000.0
const DEFAULT_DIRECTION := Vector2.DOWN

signal activated
signal deactivated
signal player_entered(player: Player)
signal player_exited(player: Player)

@export_category("Rope")
@export_range(MIN_LENGTH, MAX_LENGTH, 1.0) var length: float = 160.0:
	set(value):
		length = maxf(value, MIN_LENGTH)
		queue_redraw()
@export_range(MIN_WIDTH, MAX_WIDTH, 1.0) var width: float = 4.0:
	set(value):
		width = maxf(value, MIN_WIDTH)
		queue_redraw()
@export var rope_color := Color("#94a3b8")
@export_range(MIN_DETECTION_RADIUS, MAX_DETECTION_RADIUS, 1.0) var detection_radius: float = 160.0:
	set(value):
		detection_radius = maxf(value, MIN_DETECTION_RADIUS)
		if is_node_ready():
			_update_detection_shape()

var _active := false
var _direction := DEFAULT_DIRECTION
var _detected_player: Player

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D


func _ready() -> void:
	_update_detection_shape()
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

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


func _update_detection_shape() -> void:
	var circle := detection_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		detection_shape.shape = circle
	circle.radius = detection_radius


func _on_detection_area_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	var player := body as Player
	_detected_player = player
	activate_toward(player.global_position)
	player_entered.emit(player)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body != _detected_player:
		return

	var player := _detected_player
	_detected_player = null
	deactivate()
	player_exited.emit(player)


func _draw() -> void:
	if not _active:
		return

	draw_line(Vector2.ZERO, _direction * length, rope_color, width, true)
