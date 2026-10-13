class_name TrajectoryCalculator
extends RefCounted


static func calculate_points(
	origin: Vector2,
	initial_velocity: Vector2,
	gravity: Vector2,
	point_count: int,
	time_step: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var clamped_point_count := maxi(point_count, 0)
	var clamped_time_step := maxf(time_step, 0.0)

	for point_index in range(clamped_point_count):
		var time := point_index * clamped_time_step
		var point := origin + initial_velocity * time + gravity * time * time / 2.0
		points.append(point)

	return points
