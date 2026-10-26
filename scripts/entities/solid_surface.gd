class_name SolidSurface
extends StaticBody2D

@export_category("Surface")
@export var size: Vector2 = Vector2(256.0, 32.0):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		if is_node_ready():
			_update_collision_shape()
			queue_redraw()
@export var surface_color := Color("#64748b")
@export var obstacle_color := Color("#ef4444")
@export var is_obstacle: bool = false:
	set(value):
		is_obstacle = value
		_update_obstacle_group()
		if is_node_ready():
			queue_redraw()

@export_category("Collision")
## Surface bounce. Godot combines the bounce of both bodies, capped at 1.
@export_range(0.0, 1.0, 0.05) var bounce: float = 0.0:
	set(value):
		bounce = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_apply_physics_material()
## Surface friction. Godot uses the lower friction value between both bodies.
@export_range(0.0, 1.0, 0.05) var friction: float = 0.8:
	set(value):
		friction = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_apply_physics_material()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var _has_animated_sprite := false


func _ready() -> void:
	_has_animated_sprite = get_node_or_null("AnimatedSprite2D") != null
	_update_obstacle_group()
	if collision_shape.shape == null:
		collision_shape.shape = RectangleShape2D.new()
	else:
		collision_shape.shape = collision_shape.shape.duplicate()
	_update_collision_shape()
	_apply_physics_material()
	queue_redraw()


func _update_obstacle_group() -> void:
	if is_obstacle:
		add_to_group(Events.OBSTACLE_GROUP)
	else:
		remove_from_group(Events.OBSTACLE_GROUP)


func _update_collision_shape() -> void:
	if collision_shape == null:
		return
	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collision_shape.shape = rectangle
	rectangle.size = size


func _apply_physics_material() -> void:
	var surface_material := physics_material_override as PhysicsMaterial
	if surface_material == null:
		surface_material = PhysicsMaterial.new()
		physics_material_override = surface_material
	surface_material.bounce = bounce
	surface_material.friction = friction


func _draw() -> void:
	if _has_animated_sprite:
		return
	var bounds := Rect2(-size / 2.0, size)
	draw_rect(bounds, obstacle_color if is_obstacle else surface_color)
	draw_line(bounds.position, Vector2(bounds.end.x, bounds.position.y), Color.WHITE, 2.0)
