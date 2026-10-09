extends RigidBody2D
class_name Player

enum State { READY, MOVING, STOPPED }

const STOP_SPEED_SQUARED_THRESHOLD := 3.0
const STOP_CONFIRMATION_TIME := 0.1
const OUTLINE_SEGMENTS := 32
const OUTLINE_WIDTH := 2.0
const LAUNCH_ARROW_WIDTH := 3.0

signal launched(velocity: Vector2)
signal stopped
signal obstacle_hit
signal launch_parameters_changed(speed: float, angle_degrees: float)

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
@export_range(0.0, 180.0, 1.0) var launch_angle_degrees: float = 0.0
@export_range(0.0, 1000.0, 1.0) var launch_speed: float = 100.0

var _state: State = State.READY
var launch_velocity := Vector2.ZERO
var _stop_detection_enabled := true
var _stop_detection_time := 0.0
var _obstacle_hit_queued := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if collision_shape.shape != null:
		collision_shape.shape = collision_shape.shape.duplicate()
	_update_collision_shape()
	freeze = true
	set_physics_process(false)
	queue_redraw()


func _integrate_forces(state_2d: PhysicsDirectBodyState2D) -> void:
	if _state == State.MOVING:
		for contact_index in range(state_2d.get_contact_count()):
			var body := state_2d.get_contact_collider_object(contact_index)
			if body is SolidSurface and body.is_obstacle:
				_queue_obstacle_hit()
				break


func _physics_process(delta: float) -> void:
	if not _stop_detection_enabled or _state != State.MOVING:
		return

	if linear_velocity.length_squared() < STOP_SPEED_SQUARED_THRESHOLD:
		_stop_detection_time += delta
		if _stop_detection_time < STOP_CONFIRMATION_TIME:
			return

		_state = State.STOPPED
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


func is_ready() -> bool:
	return _state == State.READY


func set_stop_detection_enabled(enabled: bool) -> void:
	_stop_detection_enabled = enabled
	if not enabled:
		_stop_detection_time = 0.0


func set_launch_parameters(speed: float, angle_degrees: float) -> void:
	launch_speed = maxf(speed, 0.0)
	launch_angle_degrees = minf(angle_degrees, 360)
	launch_velocity = Vector2.RIGHT.rotated(-deg_to_rad(launch_angle_degrees)) * launch_speed
	launch_parameters_changed.emit(launch_speed, launch_angle_degrees)
	queue_redraw()


func launch() -> void:
	if _state != State.READY:
		return
	set_launch_parameters(launch_speed, launch_angle_degrees)
	freeze = false
	linear_velocity = launch_velocity
	_stop_detection_time = 0.0
	_state = State.MOVING
	set_physics_process(true)
	launched.emit(launch_velocity)
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
	draw_colored_polygon(PackedVector2Array([tip, base + side * head * 0.6, base - side * head * 0.6]), arrow_color)
