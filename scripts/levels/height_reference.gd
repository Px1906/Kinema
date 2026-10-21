@tool
class_name HeightReference
extends Marker2D
## Altura zero da fase para o cálculo da energia potencial. Use um por fase.

const GROUP := "height_reference"
const LINE_HALF_LENGTH := 64.0
const LINE_WIDTH := 1.0

@export var line_color := Color("#94a3b8", 0.6)
## Opcional. Se definido (ex.: o Player), a altura zero fica na posição inicial dele:
## no editor acompanha o nó; no jogo, fica fixa onde ele começou a fase.
@export var start_node: Node2D:
	set(value):
		start_node = value
		_snap_to_start_node()


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	_snap_to_start_node()
	# Só o editor precisa acompanhar o nó; no jogo a posição inicial não muda mais.
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	_snap_to_start_node()


func _snap_to_start_node() -> void:
	if start_node == null or not is_inside_tree() or not start_node.is_inside_tree():
		return
	if global_position != start_node.global_position:
		global_position = start_node.global_position


func _draw() -> void:
	draw_dashed_line(
		Vector2.LEFT * LINE_HALF_LENGTH, Vector2.RIGHT * LINE_HALF_LENGTH, line_color, LINE_WIDTH
	)


## Altura em metros de um ponto global acima desta referência.
func get_height_meters(global_point: Vector2) -> float:
	return PhysicsUnits.pixels_to_meters(global_position.y - global_point.y)
