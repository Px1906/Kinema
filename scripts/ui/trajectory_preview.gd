class_name TrajectoryPreview
extends Node2D

@export var player: Player

@export_category("Preview")
@export_range(2, 64, 1) var point_count: int = 24
@export_range(0.01, 1.0, 0.01) var time_step: float = 0.08
@export var point_radius: float = 3.0
@export var point_color := Color("#facc15", 0.65)

var _points := PackedVector2Array()
var _first_visible_point := 0


func _ready() -> void:
	if player == null:
		push_warning("TrajectoryPreview: assign the 'Player' property in the Inspector.")
		return

	player.launch_parameters_changed.connect(_on_launch_parameters_changed)
	player.state_changed.connect(_on_player_state_changed)
	_update_preview()


func _on_launch_parameters_changed(_speed: float, _angle_degrees: float) -> void:
	_update_preview()


func _on_player_state_changed(_state: Player.State) -> void:
	_update_preview()


func _update_preview() -> void:
	visible = player != null and player.can_launch()
	if not visible:
		_points.clear()
		queue_redraw()
		return

	var gravity := Vector2(
		ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	) * float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var launch_direction := Vector2.RIGHT.rotated(
		deg_to_rad(-player.launch_angle_degrees)
	)
	var initial_velocity := (
		launch_direction
		* player.launch_speed
		* player.fator_velocidade_lancamento
	)
	var physics_ticks_per_second := float(
		ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
	)
	_points = TrajectoryCalculator.calculate_points(
		player.global_position,
		initial_velocity,
		gravity,
		point_count,
		time_step,
		player.gravity_scale,
		_get_total_linear_damp(),
		1.0 / physics_ticks_per_second
	)
	_points = _stop_at_first_collision(_points)
	_first_visible_point = _get_first_visible_point()
	queue_redraw()


func _get_total_linear_damp() -> float:
	if player.linear_damp_mode == RigidBody2D.DAMP_MODE_REPLACE:
		return player.linear_damp

	return player.linear_damp + float(
		ProjectSettings.get_setting("physics/2d/default_linear_damp")
	)


func _stop_at_first_collision(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 2:
		return points

	var space_state := get_world_2d().direct_space_state
	var query_shape := CircleShape2D.new()
	query_shape.radius = player.radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = query_shape
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]

	var collision_points := PackedVector2Array([points[0]])
	for point_index in range(1, points.size()):
		var previous_point := points[point_index - 1]
		var motion := points[point_index] - previous_point
		query.transform = Transform2D(0.0, previous_point)
		query.motion = motion
		var cast_result := space_state.cast_motion(query)
		if cast_result.size() >= 2 and cast_result[0] < 1.0:
			collision_points.append(previous_point + motion * cast_result[0])
			break

		collision_points.append(points[point_index])

	return collision_points


func _get_first_visible_point() -> int:
	var preview_start_distance := player.radius + 4.0
	for point_index in range(_points.size()):
		if player.global_position.distance_to(_points[point_index]) >= preview_start_distance:
			return point_index

	return _points.size()


func _draw() -> void:
	for point_index in range(_first_visible_point, _points.size()):
		draw_circle(to_local(_points[point_index]), point_radius, point_color)
