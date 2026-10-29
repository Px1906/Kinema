class_name TrajectoryPreview
extends Node2D

@export var player: Player

@export_category("Preview")
@export_range(2, 64, 1) var point_count: int = 24
## Limite de círculos enquanto a bola está na corda, separado do lançamento.
@export_range(2, 64, 1) var attached_point_count: int = 12
## Intervalo entre círculos na corda: 20% menor que o do lançamento, mais juntos.
@export_range(0.01, 1.0, 0.001) var attached_time_step: float = 0.064
@export_range(0.01, 1.0, 0.01) var time_step: float = 0.08
@export var point_radius: float = 3.0
@export var point_color := Color(Color.BLACK, 0.65)

var _points := PackedVector2Array()
var _first_visible_point := 0
var _preview_dirty := false
var _gravity := Vector2.ZERO
var _simulation_step := 0.0
var _query_shape: CircleShape2D
var _query := PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	if player == null:
		push_warning("TrajectoryPreview: assign the 'Player' property in the Inspector.")
		return

	_cache_physics_parameters()
	player.launch_parameters_changed.connect(_on_launch_parameters_changed)
	player.state_changed.connect(_on_player_state_changed)
	_request_preview_update()


func _process(_delta: float) -> void:
	# Na corda a bola se move a cada quadro: a prévia acompanha sem precisar de sinal.
	var attached := player != null and player.get_state() == Player.State.ATTACHED
	if not _preview_dirty and not attached:
		set_process(false)
		return

	_preview_dirty = false
	_update_preview()


func _on_launch_parameters_changed(_speed: float, _angle_degrees: float) -> void:
	_request_preview_update()


func _on_player_state_changed(_state: Player.State) -> void:
	_request_preview_update()


func _request_preview_update() -> void:
	_preview_dirty = true
	set_process(true)


func _cache_physics_parameters() -> void:
	var gravity_direction: Vector2 = ProjectSettings.get_setting(
		"physics/2d/default_gravity_vector"
	)
	var gravity_strength: float = float(
		ProjectSettings.get_setting("physics/2d/default_gravity")
	)
	_gravity = gravity_direction * gravity_strength
	var physics_ticks_per_second: float = float(
		ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
	)
	_simulation_step = 1.0 / maxf(physics_ticks_per_second, 1.0)
	_query_shape = CircleShape2D.new()
	_query.shape = _query_shape
	_query.exclude = [player.get_rid()]


func _update_preview() -> void:
	var attached := player.get_state() == Player.State.ATTACHED
	visible = player.can_launch() or attached
	if not visible:
		_points.clear()
		queue_redraw()
		return

	# Na corda, mostra o que aconteceria se a bola fosse solta agora: sai pela
	# tangente com a velocidade atual e passa a cair pela gravidade.
	var initial_velocity := (
		player.get_current_velocity() if attached else player.get_initial_velocity()
	)
	_points = TrajectoryCalculator.calculate_points(
		player.global_position,
		initial_velocity,
		_gravity,
		attached_point_count if attached else point_count,
		attached_time_step if attached else time_step,
		player.gravity_scale,
		player.get_total_linear_damp(),
		_simulation_step
	)
	_points = _stop_at_first_collision(_points)
	_first_visible_point = _get_first_visible_point()
	queue_redraw()


func _stop_at_first_collision(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 2:
		return points

	var space_state := get_world_2d().direct_space_state
	_query_shape.radius = player.get_collision_radius()
	_query.collision_mask = player.collision_mask

	var collision_points := PackedVector2Array([points[0]])
	for point_index in range(1, points.size()):
		var previous_point := points[point_index - 1]
		var motion := points[point_index] - previous_point
		_query.transform = Transform2D(0.0, previous_point)
		_query.motion = motion
		var cast_result := space_state.cast_motion(_query)
		if cast_result.size() >= 2 and cast_result[0] < 1.0:
			if cast_result[0] <= 0.0 and point_index == 1:
				collision_points.append(points[point_index])
				continue
			collision_points.append(previous_point + motion * cast_result[0])
			break

		collision_points.append(points[point_index])

	return collision_points


func _get_first_visible_point() -> int:
	if _points.size() <= 1:
		return _points.size()

	var preview_start_distance := player.get_collision_radius() + Player.LAUNCH_ARROW_OFFSET
	for point_index in range(_points.size()):
		if player.global_position.distance_to(_points[point_index]) >= preview_start_distance:
			return point_index

	return 1


func _draw() -> void:
	for point_index in range(_first_visible_point, _points.size()):
		draw_circle(to_local(_points[point_index]), point_radius, point_color)
