extends StaticBody2D
class_name SolidSurface

@export_category("Superfície")
@export var size: Vector2 = Vector2(256.0, 32.0):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		if is_inside_tree():
			_update_collision_shape()
			queue_redraw()
@export var surface_color := Color("#64748b")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_update_collision_shape()
	queue_redraw()


func _update_collision_shape() -> void:
	if collision_shape == null:
		return
	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collision_shape.shape = rectangle
	rectangle.size = size


func _draw() -> void:
	var bounds := Rect2(-size / 2.0, size)
	draw_rect(bounds, surface_color)
	draw_line(bounds.position, Vector2(bounds.end.x, bounds.position.y), Color.WHITE, 2.0)
