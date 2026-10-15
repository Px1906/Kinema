@tool
class_name HeightReference
extends Marker2D
## Altura zero da fase para o cálculo da energia potencial. Use um por fase.

const GROUP := "height_reference"
const LINE_HALF_LENGTH := 64.0
const LINE_WIDTH := 1.0

@export var line_color := Color("#94a3b8", 0.6)


func _enter_tree() -> void:
	add_to_group(GROUP)


func _draw() -> void:
	draw_dashed_line(
		Vector2.LEFT * LINE_HALF_LENGTH, Vector2.RIGHT * LINE_HALF_LENGTH, line_color, LINE_WIDTH
	)


## Altura em metros de um ponto global acima desta referência.
func get_height_meters(global_point: Vector2) -> float:
	return PhysicsUnits.pixels_to_meters(global_position.y - global_point.y)
