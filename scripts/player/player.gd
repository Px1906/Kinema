extends RigidBody2D
class_name Player

enum State { PREPARANDO, MOVENDO, PAROU }

const STOP_SPEED_SQUARED_THRESHOLD := 3.0
const OUTLINE_SEGMENTS := 32
const OUTLINE_WIDTH := 2.0
const LAUNCH_ARROW_WIDTH := 3.0

signal launched(velocity: Vector2)
signal stopped
signal reset
signal obstacle_hit
signal launch_parameters_changed(speed: float, angle_degrees: float)

@export_category("Particula")
@export var radius: float = 16.0:
	set(value):
		radius = maxf(value, 1.0)
		if is_node_ready():
			_update_collision_shape()
			queue_redraw()
@export var particle_color := Color("#5eead4")
@export var arrow_color := Color("#facc15")

@export_category("Lancamento")
@export_range(0.0, 180.0, 1.0) var launch_angle_degrees: float = 0.0
@export_range(0.0, 1000.0, 1.0) var launch_speed: float = 100.0

var state: State = State.PREPARANDO
var spawn_position: Vector2
var _spawn_launch_speed: float
var _spawn_launch_angle_degrees: float
var launch_velocity := Vector2.ZERO
var _stop_detection_enabled := true
var _obstacle_hit_queued := false
var _spawn_reset_pending := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	spawn_position = global_position
	_spawn_launch_speed = launch_speed
	_spawn_launch_angle_degrees = launch_angle_degrees
	if collision_shape.shape != null:
		collision_shape.shape = collision_shape.shape.duplicate()
	_update_collision_shape()
	freeze = true
	queue_redraw()


func _integrate_forces(state_2d: PhysicsDirectBodyState2D) -> void:
	if _spawn_reset_pending:
		state_2d.transform = Transform2D(0.0, spawn_position)
		state_2d.linear_velocity = Vector2.ZERO
		state_2d.angular_velocity = 0.0
		_spawn_reset_pending = false

	if state == State.MOVENDO:
		for contact_index in range(state_2d.get_contact_count()):
			var body := state_2d.get_contact_collider_object(contact_index)
			if body is SolidSurface and body.is_obstacle:
				_queue_obstacle_hit()
				break


func _physics_process(_delta: float) -> void:
	if _stop_detection_enabled and state == State.MOVENDO \
			and linear_velocity.length_squared() < STOP_SPEED_SQUARED_THRESHOLD:
		state = State.PAROU
		stopped.emit()
		queue_redraw()


func _queue_obstacle_hit() -> void:
	if _obstacle_hit_queued:
		return

	_obstacle_hit_queued = true
	call_deferred("_notify_obstacle_hit")


func _notify_obstacle_hit() -> void:
	_obstacle_hit_queued = false
	if state == State.MOVENDO:
		obstacle_hit.emit()


func set_stop_detection_enabled(enabled: bool) -> void:
	_stop_detection_enabled = enabled


func set_launch_parameters(speed: float, angle_degrees: float) -> void:
	launch_speed = maxf(speed, 0.0)
	launch_angle_degrees = minf(angle_degrees, 360)
	launch_velocity = Vector2.RIGHT.rotated(-deg_to_rad(launch_angle_degrees)) * launch_speed
	launch_parameters_changed.emit(launch_speed, launch_angle_degrees)
	queue_redraw()


func launch() -> void:
	if state != State.PREPARANDO:
		return
	_spawn_reset_pending = false
	set_launch_parameters(launch_speed, launch_angle_degrees)
	freeze = false
	linear_velocity = launch_velocity * 2
	state = State.MOVENDO
	launched.emit(launch_velocity)
	queue_redraw()


func reset_to_spawn() -> void:
	_spawn_reset_pending = true
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = spawn_position
	rotation = 0.0
	state = State.PREPARANDO
	set_launch_parameters(_spawn_launch_speed, _spawn_launch_angle_degrees)
	reset.emit()
	queue_redraw()


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
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, OUTLINE_SEGMENTS, Color.WHITE, OUTLINE_WIDTH)

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
	draw_line(start, base, arrow_color, LAUNCH_ARROW_WIDTH)
	draw_colored_polygon(PackedVector2Array([tip, base + side * head * 0.6, base - side * head * 0.6]), arrow_color)
