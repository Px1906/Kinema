extends RigidBody2D
class_name Player

enum State { PREPARANDO, MOVENDO, PAROU }

signal launched(velocity: Vector2)
signal stopped
signal launch_parameters_changed(speed: float, angle_degrees: float)

@export_category("Particula")
@export var radius: float = 16.0:
	set(value):
		radius = maxf(value, 1.0)
		if is_inside_tree():
			_update_collision_shape()
			queue_redraw()
@export var particle_color := Color("#5eead4")
@export var arrow_color := Color("#facc15")

@export_category("Lancamento")
@export_range(0.0, 180.0, 1.0) var launch_angle_degrees: float = 0.0
@export_range(0.0, 1000.0, 1.0) var launch_speed: float = 100.0
@export var fator_velocidade_lancamento: float = 1.0
@export var inicio_suspenso: bool

var state: State = State.PREPARANDO
var spawn_position: Vector2
var launch_velocity := Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	spawn_position = global_position
	_update_collision_shape()
	freeze = true
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if state == State.MOVENDO and linear_velocity.length_squared() < 3:
		state = State.PAROU
		print("parou")
		stopped.emit()
		queue_redraw()


func set_launch_parameters(speed: float, angle_degrees: float) -> void:
	launch_speed = maxf(speed, 0.0)
	launch_angle_degrees = minf(angle_degrees, 360)
	launch_velocity = Vector2.RIGHT.rotated(deg_to_rad(-launch_angle_degrees)) * launch_speed
	launch_parameters_changed.emit(launch_speed, launch_angle_degrees)
	queue_redraw()


func launch() -> void:
	if state != State.PREPARANDO:
		return
	set_launch_parameters(launch_speed, launch_angle_degrees)
	freeze = false
	linear_velocity = launch_velocity * fator_velocidade_lancamento
	state = State.MOVENDO
	launched.emit(launch_velocity)
	queue_redraw()


func reset_to_spawn() -> void:
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = spawn_position
	state = State.PREPARANDO
	set_launch_parameters(launch_speed, launch_angle_degrees)
	queue_redraw()

func pode_mirar() -> bool:
	return state == State.PREPARANDO

func _update_collision_shape() -> void:
	if collision_shape == null:
		return
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		collision_shape.shape = circle
	circle.radius = radius

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, particle_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color.WHITE, 2.0)

	if state == State.PREPARANDO:
		_draw_launch_arrow()

func _draw_launch_arrow() -> void:
	if launch_velocity.length_squared() < 1.0:
		return
	
	var dir := launch_velocity.normalized().rotated(-global_rotation)
	var start := dir * (radius + 4.0)
	var tip := dir * (radius + 4.0 + launch_velocity.length() * 0.15)
	var head := 10.0
	var side := dir.orthogonal()
	var base := tip - dir * head
	draw_line(start, base, arrow_color, 3.0)
	draw_colored_polygon(PackedVector2Array([tip, base + side * head * 0.6, base - side * head * 0.6]), arrow_color)
