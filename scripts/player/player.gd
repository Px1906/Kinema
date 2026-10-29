class_name Player
extends RigidBody2D

enum State { READY, MOVING, STOPPED, ATTACHED, PULLED, STUCK }

signal launched(velocity: Vector2)
signal stopped
signal obstacle_hit
signal surface_collided(impact_speed: float)
signal launch_parameters_changed(speed: float, angle_degrees: float)
signal state_changed(state: State)

const MAX_SPEED := 1000.0
const MAX_ANGLE := 180.0
const STOP_SPEED_SQUARED_THRESHOLD := 3.0
const STOP_CONFIRMATION_TIME := 0.1
const BALL_FRAME_COUNT := 18
const BALL_FRAME_PATH := "res://assets/sprites/Sprite-Animacoes/Player/Frames_Player/bola_frame_%02d.png"
const LAUNCH_ARROW_WIDTH := 4.0
const LAUNCH_ARROW_OFFSET := 4.0
const LAUNCH_ARROW_HEAD_SIZE := 14.0
const LAUNCH_ARROW_HEAD_SPREAD := 0.6
const ANGLE_LABEL_ARROW_MARGIN := 4.0
const ANGLE_ARC_GAP := 18.0
const ANGLE_ARC_WIDTH := 2.0
const ANGLE_ARC_SEGMENTS := 32
const ANGLE_LABEL_GAP := 14.0
const ANGLE_LABEL_FONT_SIZE := 14
const SPEED_LABEL_FONT_SIZE := 14
const SPEED_LABEL_GAP := 6.0
const SPEED_LABEL_MIN_DISTANCE := 6.0
## Textos de referência para medir os rótulos: o tamanho não muda a cada dígito.
const SPEED_LABEL_LAYOUT_TEXT := "|v| = 00 m/s"
const ANGLE_LABEL_LAYOUT_TEXT := "180°"
const SPEED_VECTOR_MARK_WIDTH := -1.0  # Negativa: linha de 1 px na tela, a mais fina possível.
const SPEED_VECTOR_MARK_HEAD := 2.0
const SURFACE_HIT_MIN_SPEED := 50.0
const SURFACE_HIT_COOLDOWN := 0.15

@export_category("Particle")
@export var radius: float = 16.0:
	set(value):
		radius = maxf(value, 1.0)
		if is_node_ready():
			_update_collision_shape()
			_update_ball_sprite_scale()
			queue_redraw()
@export var fill_color := Color("#5eead4")
@export var arrow_color := Color.BLACK
@export var angle_color := Color.BLACK

@export_category("Launch")
@export var fator_velocidade_lancamento: float = 1.0
@export var inicio_suspenso: bool

var _state: State = State.READY
var launch_velocity := Vector2.ZERO
var launch_speed: float = 100.0
var launch_angle_degrees: float = 0.0
var _carried_velocity := Vector2.ZERO
var _stop_detection_time := 0.0
var _obstacle_hit_queued := false
var _was_frozen_before_attach := false
var _initial_global_position: Vector2 = Vector2.ZERO
var _pending_reset_position: Vector2
var _reset_pending := false
var _base_linear_damp := 0.0
var _pull_tween: Tween
var _pull_elapsed := 0.0
var _stick_tween: Tween
var _surface_hit_cooldown := 0.0
var _ball_frames: Array[Texture2D] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _ball_sprite: Sprite2D = $BallSprite


func _ready() -> void:
	if collision_shape.shape != null:
		collision_shape.shape = collision_shape.shape.duplicate()
	_update_collision_shape()
	_load_ball_frames()
	_update_ball_sprite_scale()
	_update_ball_frame()
	freeze = true
	_initial_global_position = global_position
	_base_linear_damp = linear_damp
	set_physics_process(false)
	queue_redraw()


func _integrate_forces(state_2d: PhysicsDirectBodyState2D) -> void:
	if _reset_pending:
		state_2d.transform = Transform2D(global_rotation, _pending_reset_position)
		state_2d.angular_velocity = 0.0
		if _state != State.MOVING:
			state_2d.linear_velocity = Vector2.ZERO
			state_2d.sleeping = true
		_reset_pending = false

	if _state == State.MOVING:
		var max_impact := 0.0
		for contact_index in range(state_2d.get_contact_count()):
			var body := state_2d.get_contact_collider_object(contact_index)
			if body is Node and body.is_in_group(Events.OBSTACLE_GROUP):
				_queue_obstacle_hit()
			if body is StaticBody2D:
				var normal := state_2d.get_contact_local_normal(contact_index)
				max_impact = maxf(max_impact, absf(linear_velocity.dot(normal)))
		if max_impact >= SURFACE_HIT_MIN_SPEED and _surface_hit_cooldown <= 0.0:
			_surface_hit_cooldown = SURFACE_HIT_COOLDOWN
			surface_collided.emit(max_impact)


func _physics_process(delta: float) -> void:
	if _surface_hit_cooldown > 0.0:
		_surface_hit_cooldown -= delta

	if _state != State.MOVING:
		return

	if linear_velocity.length_squared() < STOP_SPEED_SQUARED_THRESHOLD:
		_stop_detection_time += delta
		if _stop_detection_time < STOP_CONFIRMATION_TIME:
			return

		_set_state(State.STOPPED)
		set_physics_process(false)
		stopped.emit()
		queue_redraw()
	else:
		_stop_detection_time = 0.0


func _queue_obstacle_hit() -> void:
	if _obstacle_hit_queued:
		return

	_obstacle_hit_queued = true
	call_deferred("_notify_obstacle_hit")


func _notify_obstacle_hit() -> void:
	_obstacle_hit_queued = false
	if _state == State.MOVING:
		obstacle_hit.emit()


func get_state() -> State:
	return _state


func can_launch() -> bool:
	return _state == State.READY


func get_initial_global_position() -> Vector2:
	return _initial_global_position


## Velocidade real da bola em px/s, inclusive quando congelada (corda, ímã ou espinhos).
func get_current_velocity() -> Vector2:
	if _is_carried():
		return _carried_velocity
	return linear_velocity


## A bola está congelada e sendo movida por fora (corda, ímã ou espinhos), não pela física.
func _is_carried() -> bool:
	return _state in [State.ATTACHED, State.PULLED, State.STUCK]


## Usado por quem move a bola presa (ex.: corda) para informar a velocidade real.
func set_carried_velocity(velocity: Vector2) -> void:
	_carried_velocity = velocity


func apply_brake(extra_damp: float) -> void:
	linear_damp = _base_linear_damp + extra_damp


func release_brake() -> void:
	linear_damp = _base_linear_damp


func prepare_launch() -> void:
	_reset_to_ready()
	queue_redraw()


func reset_attempt(start_position: Vector2) -> void:
	# Teleporta antes de _reset_to_ready: quem ouve state_changed (ex.: a área de mira
	# do MouseControl) lê global_position e precisa já ver a posição de reinício.
	global_position = start_position
	_pending_reset_position = start_position
	_reset_pending = true
	_reset_to_ready()
	reset_physics_interpolation()
	queue_redraw()


func _reset_to_ready() -> void:
	_kill_pull_tween()
	_kill_stick_tween()
	release_brake()
	_freeze_body()
	sleeping = true
	_obstacle_hit_queued = false
	_surface_hit_cooldown = 0.0
	launch_velocity = Vector2.ZERO
	_state = State.READY
	state_changed.emit(_state)
	launch_parameters_changed.emit(launch_speed, launch_angle_degrees)


func get_min_launch_angle() -> float:
	return -MAX_ANGLE if inicio_suspenso else 0.0


func clamp_launch_angle(angle_degrees: float) -> float:
	if not inicio_suspenso and angle_degrees < 0.0:
		return 0.0 if angle_degrees >= -90.0 else MAX_ANGLE

	return clampf(angle_degrees, get_min_launch_angle(), MAX_ANGLE)


func get_launch_velocity() -> Vector2:
	return Vector2.RIGHT.rotated(deg_to_rad(-launch_angle_degrees)) * launch_speed


func get_initial_velocity() -> Vector2:
	return get_launch_velocity() * fator_velocidade_lancamento


func get_total_linear_damp() -> float:
	if linear_damp_mode == RigidBody2D.DAMP_MODE_REPLACE:
		return linear_damp

	return linear_damp + float(ProjectSettings.get_setting("physics/2d/default_linear_damp"))


func get_collision_radius() -> float:
	return radius


## Ponto mais baixo da bola, sempre para baixo, qualquer que seja a rotação.
## A altura da energia potencial é medida a partir dele.
func get_base_global_position() -> Vector2:
	return HeightReference.get_base_point(global_position, radius)


func get_ball_energy() -> BallEnergy:
	for child in get_children():
		if child is BallEnergy:
			return child
	return null


func attach_to(anchor_global_position: Vector2) -> void:
	if _state == State.ATTACHED:
		return

	_was_frozen_before_attach = freeze
	_freeze_body()
	global_position = anchor_global_position
	_set_state(State.ATTACHED)
	queue_redraw()


## Puxa a bola até o ponto como um ímã: a curva sai na direção em que ela vinha,
## passa um pouco do alvo e volta. No fim, a bola fica suspensa ali, parada.
## velocity_influence: quanto a velocidade de entrada entorta a curva (segundos de "embalo").
## Retorna false se a bola não estava em movimento e o puxão foi ignorado.
func pull_to(target_global_position: Vector2, duration: float, velocity_influence: float) -> bool:
	if _state != State.MOVING:
		return false

	var start := global_position
	var control := start + linear_velocity * velocity_influence
	_freeze_body()
	_set_state(State.PULLED)
	queue_redraw()

	_kill_pull_tween()
	_pull_elapsed = 0.0
	_pull_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_pull_tween.tween_method(
		_set_pull_progress.bind(start, control, target_global_position), 0.0, 1.0, duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pull_tween.tween_callback(_finish_pull)
	return true


## Curva de Bézier quadrática de start até target, entortada por control.
func _set_pull_progress(t: float, start: Vector2, control: Vector2, target: Vector2) -> void:
	var previous := global_position
	global_position = start.lerp(control, t).lerp(control.lerp(target, t), t)
	# Delta medido pelo próprio tween: vale em qualquer process mode.
	var elapsed := _pull_tween.get_total_elapsed_time()
	var step := elapsed - _pull_elapsed
	_pull_elapsed = elapsed
	if step > 0.0:
		set_carried_velocity((global_position - previous) / step)


## Continua congelada no alvo e para como numa parada normal: quem ouve stopped
## (o LevelController) prepara o próximo lançamento a partir daqui.
func _finish_pull() -> void:
	_pull_tween = null
	# Outro caminho (corda, reinício) pode ter mudado o estado durante o puxão.
	if _state != State.PULLED:
		return
	_carried_velocity = Vector2.ZERO
	_set_state(State.STOPPED)
	stopped.emit()
	queue_redraw()


## Para a bola e tira da física: congela, zera velocidades e a detecção de parada.
func _freeze_body() -> void:
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	_stop_detection_time = 0.0
	set_physics_process(false)


func _kill_pull_tween() -> void:
	if _pull_tween != null:
		_pull_tween.kill()
		_pull_tween = null


## Finca a bola (ex.: nos espinhos): ela segue na direção em que vinha, freando até
## parar no máximo max_depth px adiante, fica presa por hold_time e então emite
## obstacle_hit, como uma batida em obstáculo. stop_duration é o tempo da freada
## sem o limite de profundidade.
func stick_into(stop_duration: float, max_depth: float, hold_time: float) -> void:
	if _state != State.MOVING:
		return

	var velocity := linear_velocity
	var speed := velocity.length()
	# Desaceleração constante: anda v·t/2 até parar. Limitada, freia mais forte.
	var depth := minf(speed * stop_duration / 2.0, max_depth)
	var duration := 2.0 * depth / speed if speed > 0.0 else 0.0
	var start := global_position
	var target := start + velocity.normalized() * depth
	_freeze_body()
	_set_state(State.STUCK)
	queue_redraw()

	_kill_stick_tween()
	_stick_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	if duration > 0.0:
		# QUAD + EASE_OUT é exatamente o movimento com desaceleração constante.
		_stick_tween.tween_method(
			_set_stick_progress.bind(start, target), 0.0, 1.0, duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_stick_tween.tween_callback(set_carried_velocity.bind(Vector2.ZERO))
	_stick_tween.tween_interval(hold_time)
	_stick_tween.tween_callback(_finish_stick)


func _set_stick_progress(t: float, start: Vector2, target: Vector2) -> void:
	var previous := global_position
	global_position = start.lerp(target, t)
	set_carried_velocity((global_position - previous) / get_physics_process_delta_time())


func _finish_stick() -> void:
	_stick_tween = null
	if _state == State.STUCK:
		obstacle_hit.emit()


func _kill_stick_tween() -> void:
	if _stick_tween != null:
		_stick_tween.kill()
		_stick_tween = null


func detach(velocity: Vector2) -> void:
	if _state != State.ATTACHED:
		return

	freeze = _was_frozen_before_attach
	linear_velocity = velocity
	angular_velocity = 0.0
	_set_state(State.READY if freeze else State.MOVING)
	_stop_detection_time = 0.0
	set_physics_process(_state == State.MOVING)
	queue_redraw()

func set_launch_parameters(speed: float, angle_degrees: float) -> void:
	launch_speed = clampf(speed, 0.0, MAX_SPEED)
	launch_angle_degrees = clamp_launch_angle(angle_degrees)
	launch_velocity = get_launch_velocity()
	launch_parameters_changed.emit(launch_speed, launch_angle_degrees)
	queue_redraw()


func launch() -> void:
	if not can_launch():
		return
	set_launch_parameters(launch_speed, launch_angle_degrees)
	freeze = false
	sleeping = false
	linear_velocity = get_initial_velocity()
	_stop_detection_time = 0.0
	_set_state(State.MOVING)
	set_physics_process(true)
	launched.emit(launch_velocity)
	queue_redraw()


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return

	_state = new_state
	state_changed.emit(_state)


func _update_collision_shape() -> void:
	if collision_shape == null:
		return
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		collision_shape.shape = circle
	circle.radius = radius


func _process(_delta: float) -> void:
	_update_ball_frame()


func _load_ball_frames() -> void:
	for i in range(1, BALL_FRAME_COUNT + 1):
		_ball_frames.append(load(BALL_FRAME_PATH % i))


func _update_ball_sprite_scale() -> void:
	if _ball_frames.is_empty() or _ball_sprite == null:
		return
	var tex_size := _ball_frames[0].get_size()
	var desired_diameter := radius * 2.4
	_ball_sprite.scale = Vector2.ONE * (desired_diameter / maxf(tex_size.x, tex_size.y))


func _update_ball_frame() -> void:
	if _ball_frames.is_empty() or _ball_sprite == null:
		return
	_ball_sprite.rotation = -rotation
	var angle := fposmod(rotation, TAU)
	var frame_index := int(angle / TAU * BALL_FRAME_COUNT) % BALL_FRAME_COUNT
	_ball_sprite.texture = _ball_frames[frame_index]


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	if _state == State.READY:
		_draw_launch_arrow()
		_draw_launch_angle()
		_draw_launch_speed()


## Arco do eixo horizontal até a seta, com o ângulo em graus. Desenha num referencial
## alinhado ao mundo: o eixo fica horizontal e o texto legível mesmo com a bola girada.
func _draw_launch_angle() -> void:
	if launch_velocity.length_squared() < 1.0:
		return

	draw_set_transform(Vector2.ZERO, -global_rotation)
	var arc_radius := radius + LAUNCH_ARROW_OFFSET + ANGLE_ARC_GAP
	var axis_start := Vector2.RIGHT * (radius + LAUNCH_ARROW_OFFSET)
	var axis_end := Vector2.RIGHT * arc_radius
	draw_line(axis_start, axis_end, angle_color, ANGLE_ARC_WIDTH, true)

	# Ângulo positivo aponta para cima; no canvas o y cresce para baixo, daí o sinal.
	var end_angle := deg_to_rad(-launch_angle_degrees)
	if not is_zero_approx(end_angle):
		draw_arc(
			Vector2.ZERO,
			arc_radius,
			0.0,
			end_angle,
			ANGLE_ARC_SEGMENTS,
			angle_color,
			ANGLE_ARC_WIDTH,
			true
		)

	var font := ThemeDB.fallback_font
	# draw_string posiciona pela linha de base, que fica a ascent do topo do retângulo.
	var baseline := _get_angle_label_rect().position
	baseline.y += font.get_ascent(ANGLE_LABEL_FONT_SIZE)
	draw_string(
		font,
		baseline,
		_get_angle_label_text(),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		ANGLE_LABEL_FONT_SIZE,
		angle_color
	)
	draw_set_transform(Vector2.ZERO)


func _get_angle_label_text() -> String:
	return "%d°" % AttributeFormat.round_value(launch_angle_degrees)


## Retângulo do texto do ângulo no referencial alinhado ao mundo, já afastado da seta.
func _get_angle_label_rect() -> Rect2:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(
		_get_angle_label_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, ANGLE_LABEL_FONT_SIZE
	)
	var end_angle := deg_to_rad(-launch_angle_degrees)
	var arc_radius := radius + LAUNCH_ARROW_OFFSET + ANGLE_ARC_GAP
	var label_center := Vector2.RIGHT.rotated(end_angle * 0.5) * (arc_radius + ANGLE_LABEL_GAP)
	label_center = _move_label_off_arrow(label_center, text_size, Vector2.RIGHT.rotated(end_angle))
	return Rect2(label_center - text_size * 0.5, text_size)


## Se o texto cairia sobre a seta (ângulos pequenos ou seta longa), empurra-o para o
## lado da seta oposto ao arco, encostado nela. Fora disso, devolve o centro como está.
func _move_label_off_arrow(
	label_center: Vector2, text_size: Vector2, arrow_dir: Vector2
) -> Vector2:
	var arrow_start := radius + LAUNCH_ARROW_OFFSET
	var arrow_end := arrow_start + _get_launch_arrow_length()
	var arrow_half_width := LAUNCH_ARROW_HEAD_SIZE * LAUNCH_ARROW_HEAD_SPREAD

	var away := arrow_dir.orthogonal()
	var away_dot_axis := away.dot(Vector2.RIGHT)
	# Na horizontal o arco não tem lado: o texto vai para cima.
	if absf(away_dot_axis) < 0.01:
		if away.y > 0.0:
			away = -away
	elif away_dot_axis > 0.0:
		away = -away

	# Meia extensão do retângulo do texto ao longo da seta e da perpendicular.
	var half_along := absf(arrow_dir.x) * text_size.x * 0.5 + absf(arrow_dir.y) * text_size.y * 0.5
	var half_across := absf(away.x) * text_size.x * 0.5 + absf(away.y) * text_size.y * 0.5
	var along := label_center.dot(arrow_dir)
	var across := label_center.dot(away)
	var overlaps := along + half_along >= arrow_start and along - half_along <= arrow_end \
		and absf(across) < half_across + arrow_half_width
	if not overlaps:
		return label_center

	return arrow_dir * along + away * (half_across + arrow_half_width + ANGLE_LABEL_ARROW_MARGIN)


## Comprimento da seta em px, na escala do mundo: a bola saindo a N m/s ganha uma
## seta de N metros (o mesmo número que o painel mostra, já com o fator de lançamento).
func _get_launch_arrow_length() -> float:
	return PhysicsUnits.meters_to_pixels(_get_exit_speed_mps())


## Velocidade com que a bola sai, em m/s, já com o fator de lançamento.
func _get_exit_speed_mps() -> float:
	return PhysicsUnits.pixels_to_meters(launch_velocity.length() * fator_velocidade_lancamento)


func _draw_launch_arrow() -> void:
	if launch_velocity.length_squared() < 1.0:
		return

	var dir := launch_velocity.normalized().rotated(-global_rotation)
	var start := dir * (radius + LAUNCH_ARROW_OFFSET)
	var length := _get_launch_arrow_length()
	var tip := dir * (radius + LAUNCH_ARROW_OFFSET + length)
	var head := LAUNCH_ARROW_HEAD_SIZE
	var side := dir.orthogonal()
	var base := tip - dir * head
	draw_line(start, base, arrow_color, LAUNCH_ARROW_WIDTH)
	var arrow_points := PackedVector2Array([
		tip,
		base + side * head * LAUNCH_ARROW_HEAD_SPREAD,
		base - side * head * LAUNCH_ARROW_HEAD_SPREAD,
	])
	draw_colored_polygon(arrow_points, arrow_color)


## Módulo da velocidade (|v⃗| = N m/s) sobre o meio da seta, do lado de cima da tela.
## Como o ângulo, desenha num referencial alinhado ao mundo para o texto ficar legível.
func _draw_launch_speed() -> void:
	if launch_velocity.length_squared() < 1.0:
		return

	draw_set_transform(Vector2.ZERO, -global_rotation)
	var font := ThemeDB.fallback_font
	var prefix := "|"
	var symbol := "v"
	var text := "%s%s| = %s" % [prefix, symbol, AttributeFormat.format_speed(_get_exit_speed_mps())]
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SPEED_LABEL_FONT_SIZE)

	var layout_size := font.get_string_size(
		SPEED_LABEL_LAYOUT_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, SPEED_LABEL_FONT_SIZE
	)
	var dir := launch_velocity.normalized()
	# Perpendicular à seta apontando para cima na tela (y cresce para baixo).
	var up := dir.orthogonal()
	if up.y > 0.0:
		up = -up
	# Meia extensão do retângulo do texto ao longo da seta e da perpendicular.
	var half_along := absf(dir.x) * layout_size.x * 0.5 + absf(dir.y) * layout_size.y * 0.5
	var half_across := absf(up.x) * layout_size.x * 0.5 + absf(up.y) * layout_size.y * 0.5

	# Fica no meio da seta, mas com a borda mais próxima da bola sempre fora da zona do
	# arco e do texto do ângulo. Tudo contínuo: o rótulo não salta quando a seta encurta.
	var middle := radius + LAUNCH_ARROW_OFFSET + _get_launch_arrow_length() * 0.5
	var along := maxf(middle, _get_angle_zone_radius() + SPEED_LABEL_MIN_DISTANCE + half_along)
	var across := half_across + LAUNCH_ARROW_WIDTH * 0.5 + SPEED_LABEL_GAP
	var label_center := dir * along + up * across

	var ascent := font.get_ascent(SPEED_LABEL_FONT_SIZE)
	var baseline := label_center + Vector2(-text_size.x * 0.5, ascent - text_size.y * 0.5)
	draw_string(
		font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SPEED_LABEL_FONT_SIZE, arrow_color
	)

	# Setinha de vetor sobre o "v", no espaço livre acima das minúsculas.
	var symbol_left := baseline.x + font.get_string_size(
		prefix, HORIZONTAL_ALIGNMENT_LEFT, -1, SPEED_LABEL_FONT_SIZE
	).x
	var symbol_width := font.get_string_size(
		symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, SPEED_LABEL_FONT_SIZE
	).x
	var mark_y := baseline.y - ascent + SPEED_VECTOR_MARK_HEAD
	var mark_start := Vector2(symbol_left, mark_y)
	var mark_end := Vector2(symbol_left + symbol_width, mark_y)
	var head := SPEED_VECTOR_MARK_HEAD
	draw_line(mark_start, mark_end, arrow_color, SPEED_VECTOR_MARK_WIDTH, true)
	draw_line(mark_end, mark_end + Vector2(-head, -head), arrow_color, SPEED_VECTOR_MARK_WIDTH, true)
	draw_line(mark_end, mark_end + Vector2(-head, head), arrow_color, SPEED_VECTOR_MARK_WIDTH, true)
	draw_set_transform(Vector2.ZERO)


## Raio a partir do centro da bola que contém o arco e o texto do ângulo em qualquer
## posição, inclusive quando _move_label_off_arrow o empurra para o lado da seta.
func _get_angle_zone_radius() -> float:
	var font := ThemeDB.fallback_font
	var angle_size := font.get_string_size(
		ANGLE_LABEL_LAYOUT_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, ANGLE_LABEL_FONT_SIZE
	)
	var half_diagonal := angle_size.length() * 0.5
	var label_distance := radius + LAUNCH_ARROW_OFFSET + ANGLE_ARC_GAP + ANGLE_LABEL_GAP
	var arrow_half_width := LAUNCH_ARROW_HEAD_SIZE * LAUNCH_ARROW_HEAD_SPREAD
	var max_push := half_diagonal + arrow_half_width + ANGLE_LABEL_ARROW_MARGIN
	return Vector2(label_distance, max_push).length() + half_diagonal
