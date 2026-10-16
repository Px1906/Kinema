class_name QteBarrier
extends StaticBody2D

signal triggered(barrier: QteBarrier)

const BARRIER_COLOR := Color("#f59e0b")
const BARRIER_ACTIVE_COLOR := Color("#f59e0b", 0.5)

@export_category("Barrier")
@export var size: Vector2 = Vector2(32.0, 128.0):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		if is_node_ready():
			_update_collision_shape()
			_update_trigger_shape()
			queue_redraw()

@export_category("Trigger")
@export var trigger_distance: float = 200.0:
	set(value):
		trigger_distance = maxf(value, 1.0)
		if is_node_ready():
			_update_trigger_shape()

var _active := true
var _triggered := false

@onready var barrier_shape: CollisionShape2D = $BarrierShape
@onready var trigger_area: Area2D = $TriggerArea
@onready var trigger_shape: CollisionShape2D = $TriggerArea/TriggerShape


func _ready() -> void:
	if barrier_shape.shape != null:
		barrier_shape.shape = barrier_shape.shape.duplicate()
	if trigger_shape.shape != null:
		trigger_shape.shape = trigger_shape.shape.duplicate()
	_update_collision_shape()
	_update_trigger_shape()
	trigger_area.body_entered.connect(_on_trigger_body_entered)
	queue_redraw()


func is_active() -> bool:
	return _active


func remove_barrier() -> void:
	_active = false
	barrier_shape.set_deferred("disabled", true)
	trigger_area.set_deferred("monitoring", false)
	Events.barrier_removed.emit(self)
	queue_redraw()


func reset_barrier() -> void:
	_active = true
	_triggered = false
	barrier_shape.set_deferred("disabled", false)
	trigger_area.set_deferred("monitoring", true)
	queue_redraw()


func _on_trigger_body_entered(body: Node2D) -> void:
	if not _active or _triggered:
		return
	if body is Player:
		_triggered = true
		triggered.emit(self)
		Events.qte_started.emit(self)


func _update_collision_shape() -> void:
	if barrier_shape == null:
		return
	var rect := barrier_shape.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		barrier_shape.shape = rect
	rect.size = size


func _update_trigger_shape() -> void:
	if trigger_shape == null:
		return
	var rect := trigger_shape.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		trigger_shape.shape = rect
	rect.size = Vector2(trigger_distance, size.y * 2.0)
	trigger_shape.position = Vector2(-trigger_distance / 2.0 - size.x / 2.0, 0.0)


func _draw() -> void:
	if not _active:
		return
	var bounds := Rect2(-size / 2.0, size)
	draw_rect(bounds, BARRIER_COLOR if not _triggered else BARRIER_ACTIVE_COLOR)
