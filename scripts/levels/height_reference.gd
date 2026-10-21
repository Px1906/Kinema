@tool
class_name HeightReference
extends Marker2D
## Altura zero da fase para o cálculo da energia potencial. Use um por fase.

const GROUP := "height_reference"
const LINE_HALF_LENGTH := 64.0
const LINE_WIDTH := 1.0
const LINE_DASH_LENGTH := 8.0

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
	# No editor a fase pode ser redimensionada a qualquer momento.
	queue_redraw()


func _snap_to_start_node() -> void:
	if start_node == null or not is_inside_tree() or not start_node.is_inside_tree():
		return
	if global_position != start_node.global_position:
		global_position = start_node.global_position


## Eixos tracejados com origem no marcador: o horizontal é a altura zero e o
## vertical marca o x de partida.
func _draw() -> void:
	var area := _get_local_area()
	draw_dashed_line(
		Vector2(area.position.x, 0.0), Vector2(area.end.x, 0.0),
		line_color, LINE_WIDTH, LINE_DASH_LENGTH
	)
	draw_dashed_line(
		Vector2(0.0, area.position.y), Vector2(0.0, area.end.y),
		line_color, LINE_WIDTH, LINE_DASH_LENGTH
	)


## Área (local) coberta pelos eixos: a fase inteira, lida do bounds_rect do
## LevelController; sem ele, um quadrado curto em volta do marcador.
func _get_local_area() -> Rect2:
	var level := owner as LevelController
	if level == null or level.bounds_rect == null:
		return Rect2(-Vector2.ONE * LINE_HALF_LENGTH, Vector2.ONE * LINE_HALF_LENGTH * 2.0)

	var bounds := level.bounds_rect.get_global_rect()
	return Rect2(to_local(bounds.position), Vector2.ZERO).expand(to_local(bounds.end))


## Move a altura zero (e os eixos) para um ponto global, ex.: a posição atual da bola.
func move_to(global_point: Vector2) -> void:
	global_position = global_point
	queue_redraw()


## Altura em metros de um ponto global acima desta referência.
func get_height_meters(global_point: Vector2) -> float:
	return PhysicsUnits.pixels_to_meters(global_position.y - global_point.y)
