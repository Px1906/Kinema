class_name Player
extends RigidBody2D

enum State { READY, MOVING, STOPPED, ATTACHED }

signal launched(velocity: Vector2)
signal stopped
signal obstacle_hit
signal launch_parameters_changed(speed: float, angle_degrees: float)
signal state_changed(state: State)

const MAX_SPEED := 1000.0
const MAX_ANGLE := 180.0
const STOP_SPEED_SQUARED_THRESHOLD := 3.0
const STOP_CONFIRMATION_TIME := 0.1
const OUTLINE_SEGMENTS := 32
const OUTLINE_WIDTH := 2.0
const LAUNCH_ARROW_WIDTH := 3.0
const OBSTACLE_GROUP := "obstacle"

@export_category("Particle")
@export var radius: float = 16.0:
	set(value):
		radius = maxf(value, 1.0)
		if is_node_ready():
			_update_collision_shape()
			queue_redraw()
@export var particle_color := Color("#5eead4")
@export var arrow_color := Color("#facc15")

@export_category("Launch")
@export var fator_velocidade_lancamento: float = 1.0
@export var inicio_suspenso: bool

var _state: State = State.READY
var launch_velocity := Vector2.ZERO
var launch_speed: float = 100.0
var launch_angle_degrees: float = 0.0
var _stop_detection_time := 0.0
var _obstacle_hit_queued := false
var _was_frozen_before_attach := false
var _initial_global_position: Vector2 = Vector2.ZERO
var _pending_reset_position: Vector2
var _reset_pending := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if collision_shape.shape != null:
		collision_shape.shape = collision_shape.shape.duplicate()
	_update_collision_shape()
	freeze = true
	_initial_global_position = global_position
	set_physics_process(false)
	queue_redraw()


func _integrate_forces(state_2d: PhysicsDirectBodyState2D) -> void:
	if _reset_pending:
		state_2d.transform = Transform2D(global_rotation, _pending_reset_position)
		state_2d.angular_velocity = 0.0
		if _state != State.MOVING:
			state_2d.linear_velocity = Vector2.ZERO
			state_2d.sleeping = true
		_reset_pending = false

	if _state == State.MOVING:
		for contact_index in range(state_2d.get_contact_count()):
			var body := state_2d.get_contact_collider_object(contact_index)
			if body is Node and body.is_in_group(OBSTACLE_GROUP):
				_queue_obstacle_hit()
				break


func _physics_process(delta: float) -> void:
	if _state != State.MOVING:
		return

	if linear_velocity.length_squared() < STOP_SPEED_SQUARED_THRESHOLD:
		_stop_detection_time += delta
		if _stop_detection_time < STOP_CONFIRMATION_TIME:
			return

		_set_state(State.STOPPED)
		set_physics_process(false)
		stopped.emit()
		queue_redraw()
	else:
		_stop_detection_time = 0.0


func _queue_obstacle_hit() -> void:
	if _obstacle_hit_queued:
		return

	_obstacle_hit_queued = true
	call_deferred("_notify_obstacle_hit")


func _notify_obstacle_hit() -> void:
	_obstacle_hit_queued = false
	if _state == State.MOVING:
		obstacle_hit.emit()


func get_state() -> State:
	return _state


func can_launch() -> bool:
	return _state == State.READY


func get_initial_global_position() -> Vector2:
	return _initial_global_position


func reset_attempt(start_position: Vector2) -> void:
	freeze = true
	sleeping = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = start_position
	_pending_reset_position = start_position
	_reset_pending = true
	reset_physics_interpolation()
	_stop_detection_time = 0.0
	_obstacle_hit_queued = false
	set_physics_process(false)
	_set_state(State.READY)
	queue_redraw()


func get_min_launch_angle() -> float:
	return -MAX_ANGLE if inicio_suspenso else 0.0


func clamp_launch_angle(angle_degrees: float) -> float:
	if not inicio_suspenso and angle_degrees < 0.0:
		return 0.0 if angle_degrees >= -90.0 else MAX_ANGLE

	return clampf(angle_degrees, get_min_launch_angle(), MAX_ANGLE)


func attach_to(anchor_global_position: Vector2) -> void:
	if _state == State.ATTACHED:
		return

	_was_frozen_before_attach = freeze
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = anchor_global_position
	_stop_detection_time = 0.0
	_set_state(State.ATTACHED)
	set_physics_process(false)
	queue_redraw()


func detach(velocity: Vector2) -> void:
	if _state != State.ATTACHED:
		return

	freeze = _was_frozen_before_attach
	linear_velocity = velocity
	angular_velocity = 0.0
	_set_state(State.READY if freeze else State.MOVING)
	_stop_detection_time = 0.0
	set_physics_process(_state == State.MOVING)
	queue_redraw()

func set_launch_parameters(speed: float, angle_degrees: float) -> void:
	launch_speed = clampf(speed, 0.0, MAX_SPEED)
	launch_angle_degrees = clamp_launch_angle(angle_degrees)
	launch_velocity = Vector2.RIGHT.rotated(deg_to_rad(-launch_angle_degrees)) * launch_speed
	launch_parameters_changed.emit(launch_speed, launch_angle_degrees)
	queue_redraw()


func launch() -> void:
	if not can_launch():
		return
	set_launch_parameters(launch_speed, launch_angle_degrees)
	freeze = false
	sleeping = false
	linear_velocity = launch_velocity * fator_velocidade_lancamento
	_stop_detection_time = 0.0
	_set_state(State.MOVING)
	set_physics_process(true)
	launched.emit(launch_velocity)
	queue_redraw()


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return

	_state = new_state
	state_changed.emit(_state)


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

	if _state == State.READY:
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
	var arrow_points := PackedVector2Array([
		tip,
		base + side * head * 0.6,
		base - side * head * 0.6,
	])
	draw_colored_polygon(arrow_points, arrow_color)
