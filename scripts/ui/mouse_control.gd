extends Control
class_name MouseControl

@export var player: Player

@export_category("Vetor de lancamento")
@export var inverter_direcao: bool = false
@export var fator_velocidade: float = 3.0
@export var velocidade_maxima: float = 1000.0
@export var distancia_minima: float = 5.0
@export_range(16.0, 512.0, 1.0) var raio_interacao: float = 96.0

@export_category("Visual")
@export var mostrar_area: bool = false
@export var cor_area := Color(1, 1, 1, 0.08)
@export var cor_vetor := Color("#f87171")

var _arrastando := false
var _inicio := Vector2.ZERO
var _atual := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_atualizar_area_interacao()


func _process(_delta: float) -> void:
	if player == null:
		return

	var preparando := player.get_state() == Player.State.PREPARANDO
	mouse_filter = Control.MOUSE_FILTER_STOP if preparando else Control.MOUSE_FILTER_IGNORE
	if preparando:
		_atualizar_area_interacao()


func _atualizar_area_interacao() -> void:
	var diameter := raio_interacao * 2.0
	size = Vector2.ONE * diameter
	position = player.global_position - Vector2.ONE * raio_interacao


func _gui_input(event: InputEvent) -> void:
	if player == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and player.get_state() == Player.State.PREPARANDO:
			_arrastando = true
			_inicio = size / 2.0
			_atual = event.position
		else:
			_arrastando = false
		queue_redraw()
		accept_event()

	elif event is InputEventMouseMotion and _arrastando:
		if player.get_state() != Player.State.PREPARANDO:
			_arrastando = false
		else:
			_atual = event.position
			_aplicar_vetor()
		queue_redraw()
		accept_event()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and player.get_state() == Player.State.PREPARANDO and _arrastando:
			player.launch()


func _aplicar_vetor() -> void:
	var v := _atual - _inicio
	if inverter_direcao:
		v = -v
	if v.length() < distancia_minima:
		return

	var angulo := rad_to_deg(atan2(-v.y, v.x))
	if angulo < 0.0:
		angulo += 360.0
	var velocidade := minf(v.length() * fator_velocidade, velocidade_maxima)
	player.set_launch_parameters(velocidade, angulo)


func _draw() -> void:
	if mostrar_area:
		draw_rect(Rect2(Vector2.ZERO, size), cor_area)
		draw_rect(Rect2(Vector2.ZERO, size), cor_vetor, false, 1.0)
	if _arrastando:
		draw_line(_inicio, _atual, cor_vetor, 2.0)
		draw_circle(_inicio, 4.0, cor_vetor)
