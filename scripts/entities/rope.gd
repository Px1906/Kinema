extends Node2D
class_name Rope

const MIN_LENGTH := 1.0
const MAX_LENGTH := 2000.0
const MIN_WIDTH := 1.0
const MAX_WIDTH := 32.0
const DEFAULT_DIRECTION := Vector2.DOWN

signal activated
signal deactivated

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

var _active := false
var _direction := DEFAULT_DIRECTION


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


func _draw() -> void:
	if not _active:
		return

	draw_line(Vector2.ZERO, _direction * length, rope_color, width, true)
