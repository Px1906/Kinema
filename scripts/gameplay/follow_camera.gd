class_name FollowCamera
extends Camera2D
## Câmera que segue o alvo (normalmente o Player) usando a suavização nativa do Camera2D.
## Não é filha do Player para poder ter limites, zoom e reposicionamento próprios.
## Roda no passo de física, junto com o Player (RigidBody2D), para não tremer.
## Quem teleporta o alvo (ex.: reset da tentativa) chama snap_to_target() para a câmera
## pular junto em vez de deslizar. Os limites vêm do LevelController (level_bounds).
##
## O jogador controla a câmera com as ações do InputMap:
## - "zoom_in" / "zoom_out" (roda do mouse): zoom. Seguindo o alvo, o zoom é centrado
##   nele; com a câmera solta, o ponto sob o mouse fica parado.
## - "camera_pan" (botão direito, se pan_enabled): arrastar solta a câmera do alvo.
##   Ela volta a seguir quando alguém chama follow_target() (ex.: ao lançar) ou
##   snap_to_target().

## Emitido quando a câmera passa a seguir o alvo (true) ou fica solta pelo arrasto (false).
signal following_changed(is_following: bool)

@export var target: Node2D

@export_category("Zoom")
@export_range(0.1, 1.0, 0.05) var min_zoom: float = 0.5
@export_range(1.0, 8.0, 0.1) var max_zoom: float = 3.0
## Quanto cada passo da roda multiplica (ou divide) o zoom.
@export_range(1.01, 2.0, 0.01) var zoom_step: float = 1.1
## Velocidade da animação do zoom (maior = mais rápido). 0 aplica o zoom na hora.
@export_range(0.0, 30.0, 0.5) var zoom_smoothing: float = 12.0

@export_category("QTE Zoom")
@export_range(1.0, 5.0, 0.1) var qte_zoom: float = 2.0
@export_range(0.1, 2.0, 0.1) var qte_zoom_duration: float = 0.5

## Permite arrastar a câmera. O LevelController só libera enquanto a bola espera o
## lançamento, para um clique direito durante o voo não soltar a câmera sem querer.
var pan_enabled := true

var _following := true
var _panning := false
var _target_zoom := 1.0
var _zoom_anchor := Vector2.ZERO
var _pre_qte_zoom := 1.0
var _qte_active := false
var _qte_tween: Tween


func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_target_zoom = clampf(zoom.x, min_zoom, max_zoom)
	zoom = Vector2.ONE * _target_zoom
	if not is_instance_valid(target):
		push_warning("FollowCamera: assign the 'Target' property in the Inspector.")
		set_physics_process(false)
		return

	snap_to_target()

	Events.qte_started.connect(_on_qte_started)
	Events.qte_finished.connect(_on_qte_finished)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		set_physics_process(false)
		return

	if _following:
		global_position = target.global_position


func _process(delta: float) -> void:
	if _qte_active:
		return
	var current_zoom := zoom.x
	if is_equal_approx(current_zoom, _target_zoom):
		return

	var next_zoom := _target_zoom
	if zoom_smoothing > 0.0:
		next_zoom = lerpf(current_zoom, _target_zoom, 1.0 - exp(-zoom_smoothing * delta))
		if absf(next_zoom - _target_zoom) < 0.001:
			next_zoom = _target_zoom

	_apply_zoom(current_zoom, next_zoom)


## Só começa zoom e pan com eventos que a UI não consumiu (ex.: roda sobre um slider).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		_request_zoom(zoom_step, event)
	elif event.is_action_pressed("zoom_out"):
		_request_zoom(1.0 / zoom_step, event)
	elif pan_enabled and event.is_action_pressed("camera_pan"):
		_start_pan()
	else:
		return

	get_viewport().set_input_as_handled()


## Durante o arrasto o movimento é lido em _input, para não travar quando o mouse
## passa por cima da UI.
func _input(event: InputEvent) -> void:
	if not _panning:
		return

	if event.is_action_released("camera_pan"):
		_panning = false
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		global_position = _clamp_to_limits(global_position - motion.relative / zoom.x)
		reset_smoothing()


## Volta a seguir o alvo, deslizando até ele com a suavização.
func follow_target() -> void:
	_set_following(true)
	_panning = false


## Volta a seguir o alvo e move a câmera direto para ele, sem a suavização.
func snap_to_target() -> void:
	follow_target()
	if not is_instance_valid(target):
		return

	global_position = target.global_position
	reset_smoothing()


## Solta a câmera do alvo a partir do que está na tela agora (com suavização e limites).
func _start_pan() -> void:
	_panning = true
	_set_following(false)
	global_position = get_screen_center_position()
	reset_smoothing()


func _request_zoom(factor: float, event: InputEvent) -> void:
	var mouse_event := event as InputEventMouse
	_zoom_anchor = (mouse_event.position if mouse_event != null else get_viewport_rect().size / 2.0)
	_target_zoom = clampf(_target_zoom * factor, _get_min_zoom(), max_zoom)


func _apply_zoom(old_zoom: float, new_zoom: float) -> void:
	if not _following:
		# Ponto do mundo sob o mouse = centro + (mouse - meio da tela) / zoom.
		# Desloca a câmera para que esse ponto continue sob o mouse com o novo zoom.
		var from_center := _zoom_anchor - get_viewport_rect().size / 2.0
		global_position += from_center / old_zoom - from_center / new_zoom

	zoom = Vector2.ONE * new_zoom
	if not _following:
		global_position = _clamp_to_limits(global_position)
		reset_smoothing()


## Menor zoom em que a tela ainda cabe dentro dos limites (não mostra fora da fase).
func _get_min_zoom() -> float:
	var screen_size := get_viewport_rect().size
	var limits_size := Vector2(limit_right - limit_left, limit_bottom - limit_top)
	var fit_zoom := maxf(screen_size.x / limits_size.x, screen_size.y / limits_size.y)
	return clampf(maxf(min_zoom, fit_zoom), min_zoom, max_zoom)


## Mantém o centro da câmera onde os limites deixam ela ir, para o arrasto não
## "acumular" fora da fase e depois parecer travado na volta.
func _clamp_to_limits(center: Vector2) -> Vector2:
	var half_view := get_viewport_rect().size / (2.0 * zoom.x)
	var min_center := Vector2(limit_left, limit_top) + half_view
	var max_center := Vector2(limit_right, limit_bottom) - half_view
	return Vector2(
		_clamp_axis(center.x, min_center.x, max_center.x),
		_clamp_axis(center.y, min_center.y, max_center.y)
	)


func _clamp_axis(value: float, min_value: float, max_value: float) -> float:
	if min_value > max_value:
		return (min_value + max_value) / 2.0

	return clampf(value, min_value, max_value)


## Câmera está seguindo o alvo (e não solta pelo arrasto).
func is_following() -> bool:
	return _following


func _set_following(value: bool) -> void:
	if _following == value:
		return

	_following = value
	following_changed.emit(_following)


func _on_qte_started(_barrier: QteBarrier) -> void:
	_pre_qte_zoom = _target_zoom
	_qte_active = true
	_kill_qte_tween()
	var speed := 1.0 / maxf(Engine.time_scale, 0.0001)
	_qte_tween = create_tween()
	_qte_tween.set_speed_scale(speed)
	_qte_tween.tween_method(_set_zoom_direct, zoom.x, qte_zoom, qte_zoom_duration)


func _on_qte_finished(_barrier: QteBarrier, _correct: bool) -> void:
	_qte_active = false
	_kill_qte_tween()
	_qte_tween = create_tween()
	_qte_tween.tween_method(_set_zoom_direct, zoom.x, _pre_qte_zoom, qte_zoom_duration)
	_qte_tween.tween_callback(func() -> void: _target_zoom = _pre_qte_zoom)


func _set_zoom_direct(value: float) -> void:
	zoom = Vector2.ONE * value
	_target_zoom = value


func _kill_qte_tween() -> void:
	if _qte_tween != null and _qte_tween.is_valid():
		_qte_tween.kill()


func _exit_tree() -> void:
	if Events.qte_started.is_connected(_on_qte_started):
		Events.qte_started.disconnect(_on_qte_started)
	if Events.qte_finished.is_connected(_on_qte_finished):
		Events.qte_finished.disconnect(_on_qte_finished)
