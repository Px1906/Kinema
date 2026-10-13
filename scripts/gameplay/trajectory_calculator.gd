class_name TrajectoryCalculator
extends RefCounted


static func calculate_points(
	origin: Vector2,
	initial_velocity: Vector2,
	gravity: Vector2,
	point_count: int,
	time_step: float,
	gravity_scale: float = 1.0,
	linear_damp: float = 0.0,
	simulation_step: float = 0.0
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var clamped_point_count := maxi(point_count, 0)
	var clamped_time_step := maxf(time_step, 0.0)
	var clamped_simulation_step := simulation_step
	if clamped_simulation_step <= 0.0:
		clamped_simulation_step = clamped_time_step
	var velocity := initial_velocity
	var position := origin

	for point_index in range(clamped_point_count):
		points.append(position)
		var target_time := (point_index + 1) * clamped_time_step
		var simulated_time := point_index * clamped_time_step
		while simulated_time < target_time:
			var delta := minf(clamped_simulation_step, target_time - simulated_time)
			var damping_factor := 1.0 / (1.0 + maxf(linear_damp, 0.0) * delta)
			velocity += gravity * gravity_scale * delta
			velocity *= damping_factor
			position += velocity * delta
			simulated_time += delta

	return points
