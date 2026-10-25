@tool
class_name HeightReference
extends Marker2D
## Altura zero da fase para o cálculo da energia potencial. Use um por fase.
## No jogo, o jogador arrasta a origem (move nos dois eixos) ou um dos eixos
## tracejados (o horizontal move na vertical e o vertical, na horizontal).

enum DragMode { NONE, BOTH, VERTICAL, HORIZONTAL }

const GROUP := "height_reference"
const LINE_HALF_LENGTH := 64.0
const LINE_WIDTH := 1.0
const LINE_DASH_LENGTH := 8.0
const ORIGIN_RADIUS := 6.0
## Distâncias de pega em pixels de tela, independentes do zoom da câmera.
const ORIGIN_GRAB_DISTANCE := 14.0
const AXIS_GRAB_DISTANCE := 8.0

@export var line_color := Color("#94a3b8", 0.6)
@export var highlight_color := Color("#e2e8f0")
## Opcional. Se definido (ex.: o Player), a altura zero fica na posição inicial dele
## (na base, se o nó tiver "radius"): no editor acompanha o nó; no jogo, fica fixa
## onde ele começou a fase.
@export var start_node: Node2D:
	set(value):
		start_node = value
		_snap_to_start_node()

@export_category("Drag")
@export var draggable := true
## Passo do arrasto em pixels, contado a partir da posição inicial. 32 px = 1 m.
@export var snap_step: float = PhysicsUnits.PIXELS_PER_METER

## Ligado e desligado em jogo por quem controla a fase (ex.: o LevelController só
## libera o arrasto com a bola pronta para lançar). draggable é a config do Inspector.
var drag_enabled := true

var _drag_mode := DragMode.NONE
var _hover_mode := DragMode.NONE
var _drag_offset := Vector2.ZERO
var _snap_origin := Vector2.ZERO


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	_snap_to_start_node()
	_snap_origin = global_position
	# Só o editor precisa acompanhar o nó; no jogo a posição inicial não muda mais.
	set_process(Engine.is_editor_hint())
	set_process_unhandled_input(not Engine.is_editor_hint())
	# _input só fica ligado durante o arrasto.
	set_process_input(false)


func _process(_delta: float) -> void:
	_snap_to_start_node()
	# No editor a fase pode ser redimensionada a qualquer momento.
	queue_redraw()


## O clique só chega aqui se a UI (ex.: a área de lançamento em volta da bola)
## não o consumiu.
func _unhandled_input(event: InputEvent) -> void:
	if not _can_drag():
		_set_hover_mode(DragMode.NONE)
		return

	if event is InputEventMouseMotion:
		_set_hover_mode(_pick_drag_mode(get_global_mouse_position()))
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT or not button.pressed:
			return
		var mode := _pick_drag_mode(get_global_mouse_position())
		if mode == DragMode.NONE:
			return
		_drag_mode = mode
		_drag_offset = get_global_mouse_position() - global_position
		set_process_input(true)
		get_viewport().set_input_as_handled()


## Durante o arrasto o movimento é lido em _input, para não travar quando o mouse
## passa por cima da UI.
func _input(event: InputEvent) -> void:
	if not _can_drag():
		_end_drag()
		return

	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
			_end_drag()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		_drag_to(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func _can_drag() -> bool:
	return draggable and drag_enabled


func _pick_drag_mode(global_point: Vector2) -> DragMode:
	var scale_factor := get_viewport().get_canvas_transform().get_scale().x
	var local := to_local(global_point)
	if local.length() * scale_factor <= ORIGIN_GRAB_DISTANCE:
		return DragMode.BOTH

	var area := _get_local_area()
	if (
		absf(local.y) * scale_factor <= AXIS_GRAB_DISTANCE
		and local.x >= area.position.x
		and local.x <= area.end.x
	):
		return DragMode.VERTICAL
	if (
		absf(local.x) * scale_factor <= AXIS_GRAB_DISTANCE
		and local.y >= area.position.y
		and local.y <= area.end.y
	):
		return DragMode.HORIZONTAL
	return DragMode.NONE


## Move em passos de snap_step a partir da posição inicial, só no eixo pego e sem
## sair da fase.
func _drag_to(global_point: Vector2) -> void:
	var target := global_point - _drag_offset
	var step := maxf(snap_step, 1.0)
	var next_position := _snap_origin + ((target - _snap_origin) / step).round() * step

	if _drag_mode == DragMode.VERTICAL:
		next_position.x = global_position.x
	elif _drag_mode == DragMode.HORIZONTAL:
		next_position.y = global_position.y

	var bounds := _get_level_bounds()
	if bounds.has_area():
		if next_position.x < bounds.position.x or next_position.x > bounds.end.x:
			next_position.x = global_position.x
		if next_position.y < bounds.position.y or next_position.y > bounds.end.y:
			next_position.y = global_position.y

	if next_position != global_position:
		global_position = next_position
		queue_redraw()


func _end_drag() -> void:
	if _drag_mode == DragMode.NONE:
		return
	_drag_mode = DragMode.NONE
	set_process_input(false)
	_set_hover_mode(_pick_drag_mode(get_global_mouse_position()) if _can_drag() else DragMode.NONE)
	queue_redraw()


func _set_hover_mode(mode: DragMode) -> void:
	if _hover_mode == mode:
		return
	_hover_mode = mode
	Input.set_default_cursor_shape(_get_cursor_shape(mode))
	queue_redraw()


func _get_cursor_shape(mode: DragMode) -> Input.CursorShape:
	match mode:
		DragMode.BOTH:
			return Input.CURSOR_MOVE
		DragMode.VERTICAL:
			return Input.CURSOR_VSIZE
		DragMode.HORIZONTAL:
			return Input.CURSOR_HSIZE
		_:
			return Input.CURSOR_ARROW


func _snap_to_start_node() -> void:
	if start_node == null or not is_inside_tree() or not start_node.is_inside_tree():
		return
	var target := start_node.global_position
	# Lido por get(): no editor o Player não é @tool e não responde a métodos.
	var start_radius: Variant = start_node.get("radius")
	if start_radius is float:
		target += Vector2.DOWN * start_radius
	if global_position != target:
		global_position = target


## Eixos tracejados com origem no marcador: o horizontal é a altura zero e o
## vertical marca o x de partida. O eixo ou a origem sob o mouse fica destacado.
func _draw() -> void:
	var active := _drag_mode if _drag_mode != DragMode.NONE else _hover_mode
	var area := _get_local_area()
	draw_dashed_line(
		Vector2(area.position.x, 0.0),
		Vector2(area.end.x, 0.0),
		highlight_color if active in [DragMode.VERTICAL, DragMode.BOTH] else line_color,
		LINE_WIDTH,
		LINE_DASH_LENGTH
	)
	draw_dashed_line(
		Vector2(0.0, area.position.y),
		Vector2(0.0, area.end.y),
		highlight_color if active in [DragMode.HORIZONTAL, DragMode.BOTH] else line_color,
		LINE_WIDTH,
		LINE_DASH_LENGTH
	)
	draw_circle(
		Vector2.ZERO, ORIGIN_RADIUS, highlight_color if active == DragMode.BOTH else line_color
	)


## Área (local) coberta pelos eixos: a fase inteira, lida do bounds_rect do
## LevelController; sem ele, um quadrado curto em volta do marcador.
func _get_local_area() -> Rect2:
	var bounds := _get_level_bounds()
	if not bounds.has_area():
		return Rect2(-Vector2.ONE * LINE_HALF_LENGTH, Vector2.ONE * LINE_HALF_LENGTH * 2.0)

	return Rect2(to_local(bounds.position), Vector2.ZERO).expand(to_local(bounds.end))


## Limites globais da fase, ou um Rect2 vazio se não houver LevelController com bounds_rect.
func _get_level_bounds() -> Rect2:
	var level := owner as LevelController
	if level == null or level.bounds_rect == null:
		return Rect2()
	return level.bounds_rect.get_global_rect()


## Move a altura zero (e os eixos) para um ponto global, ex.: a posição atual da bola.
## Os passos do arrasto passam a contar a partir desse ponto.
func move_to(global_point: Vector2) -> void:
	global_position = global_point
	_snap_origin = global_point
	queue_redraw()


## Altura em metros de um ponto global acima desta referência.
func get_height_meters(global_point: Vector2) -> float:
	return PhysicsUnits.pixels_to_meters(global_position.y - global_point.y)
