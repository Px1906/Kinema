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

@export_category("Colisão")
## Quique da superfície. O Godot soma o quique dos dois corpos (limitado a 1).
@export_range(0.0, 1.0, 0.05) var bounce: float = 0.0:
	set(value):
		bounce = clampf(value, 0.0, 1.0)
		if is_inside_tree():
			_apply_physics_material()
## Atrito da superfície. O Godot usa o menor atrito entre os dois corpos.
@export_range(0.0, 1.0, 0.05) var friction: float = 0.8:
	set(value):
		friction = clampf(value, 0.0, 1.0)
		if is_inside_tree():
			_apply_physics_material()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_update_collision_shape()
	_apply_physics_material()
	queue_redraw()


func _update_collision_shape() -> void:
	if collision_shape == null:
		return
	# Uma forma nova por instância: a do .tscn é compartilhada entre as cópias.
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision_shape.shape = rectangle


func _apply_physics_material() -> void:
	# Um material por instância, pelo mesmo motivo da forma de colisão.
	var material := PhysicsMaterial.new()
	material.bounce = bounce
	material.friction = friction
	physics_material_override = material


func _draw() -> void:
	var bounds := Rect2(-size / 2.0, size)
	draw_rect(bounds, surface_color)
	draw_line(bounds.position, Vector2(bounds.end.x, bounds.position.y), Color.WHITE, 2.0)
