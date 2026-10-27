@tool
class_name Rope
extends Node2D
## @tool só para o editor mostrar o detection_radius ao vivo; a lógica de jogo é
## protegida por Engine.is_editor_hint().

signal activated
signal deactivated
signal player_entered(player: Player)
signal player_exited(player: Player)
signal player_attached(player: Player)
signal player_detached(player: Player)

const GROUP := &"rope"
const MIN_WIDTH := 1.0
const MAX_WIDTH := 32.0
const MIN_DETECTION_RADIUS := 1.0
const MAX_DETECTION_RADIUS := 2000.0
const DEFAULT_DETECTION_RADIUS := 160.0
const MIN_GRAVITY := 0.0
const DEFAULT_DIRECTION := Vector2.DOWN
const MIN_ATTACH_SPEED_SQUARED := 1.0
const SEGMENT_LENGTH := 12.0
const WAVE_AMPLITUDE := 3.0
const WAVE_CYCLES := 4.0
const KNOT_RADIUS := 3.0
const KNOT_INTERVAL := 4

@export_category("Rope")
@export_range(MIN_WIDTH, MAX_WIDTH, 1.0) var width: float = 4.0:
	set(value):
		width = maxf(value, MIN_WIDTH)
		queue_redraw()
@export var rope_color := Color("#94a3b8")
@export_range(MIN_DETECTION_RADIUS, MAX_DETECTION_RADIUS, 1.0) var detection_radius: float = 160.0:
	set(value):
		detection_radius = maxf(value, MIN_DETECTION_RADIUS)
		if is_node_ready():
			_update_detection_shape()
			_update_area_animation_scale()
@export_range(MIN_GRAVITY, 10.0, 0.1) var gravity_multiplier: float = 1.0
## Tolerância do cosseno entre a velocidade da bola e o vetor corda→bola para
## considerar os dois perpendiculares (0,05 ≈ 3°).
@export_range(0.0, 0.5, 0.01) var perpendicular_tolerance: float = 0.05

var _active := false
var _direction := DEFAULT_DIRECTION
var _detected_player: Player
var _attached_player: Player
var _pendulum_angle := 0.0
var _angular_velocity := 0.0
var _rope_length := 0.0
var _last_alignment := 0.0
var _has_last_alignment := false
var _area_animation_base_scale := Vector2.ONE

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var area_animation: AnimatedSprite2D = $AnimatedSprite2D


## A corda que está segurando a bola agora, entre todas as da fase; null se nenhuma.
static func get_attached_rope(tree: SceneTree) -> Rope:
	for node: Node in tree.get_nodes_in_group(GROUP):
		var rope := node as Rope
		if rope != null and rope.is_player_attached():
			return rope
	return null


func _ready() -> void:
	set_physics_process(false)
	_area_animation_base_scale = area_animation.scale
	_update_detection_shape()
	_update_area_animation_scale()
	if Engine.is_editor_hint():
		return

	add_to_group(GROUP)
	area_animation.visible = true
	area_animation.play()
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)


func _physics_process(delta: float) -> void:
	if _attached_player == null:
		_try_attach_detected_player()
		return

	if not is_instance_valid(_attached_player):
		_cleanup_attachment()
		return

	var angular_acceleration := -_get_gravity() / _rope_length * sin(_pendulum_angle)
	_angular_velocity += angular_acceleration * delta
	_pendulum_angle += _angular_velocity * delta
	_direction = Vector2.DOWN.rotated(_pendulum_angle)
	_attached_player.global_position = get_endpoint_global_position()
	_attached_player.set_carried_velocity(_get_tangential_velocity())
	queue_redraw()


func activate_toward(target_global_position: Vector2) -> void:
	var target_direction := target_global_position - global_position
	if target_direction.is_zero_approx():
		return

	_direction = target_direction.normalized()
	_rope_length = target_direction.length()
	_active = true
	activated.emit()
	queue_redraw()


func deactivate() -> void:
	if not _active:
		return

	_active = false
	deactivated.emit()
	queue_redraw()


func is_active() -> bool:
	return _active


func get_endpoint_global_position() -> Vector2:
	return global_position + _direction * _rope_length


func is_player_attached() -> bool:
	return _attached_player != null


func detach_player() -> void:
	if _attached_player == null:
		return

	var player := _attached_player
	var release_velocity := _get_tangential_velocity()
	_cleanup_attachment()
	player.detach(release_velocity)
	player_detached.emit(player)


func _update_detection_shape() -> void:
	var circle := detection_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		detection_shape.shape = circle
	circle.radius = detection_radius


func _update_area_animation_scale() -> void:
	var scale_factor := detection_radius / DEFAULT_DETECTION_RADIUS
	area_animation.scale = _area_animation_base_scale * scale_factor


func _on_detection_area_body_entered(body: Node2D) -> void:
	if _attached_player != null or not body is Player:
		return

	_detected_player = body as Player
	_has_last_alignment = false
	set_physics_process(true)


## Encaixa a bola quando a velocidade dela fica perpendicular ao vetor corda→bola,
## ou seja, quando o produto escalar dos dois vetores normalizados é quase zero.
## Como a física é discreta, também encaixa se o sinal do produto inverteu entre
## dois passos (o ângulo de 90° aconteceu entre eles).
func _try_attach_detected_player() -> void:
	if not is_instance_valid(_detected_player):
		_detected_player = null
		set_physics_process(false)
		return

	var offset := _detected_player.global_position - global_position
	var velocity := _detected_player.linear_velocity
	if (
		_detected_player.get_state() != Player.State.MOVING
		or offset.is_zero_approx()
		or velocity.length_squared() < MIN_ATTACH_SPEED_SQUARED
	):
		_has_last_alignment = false
		return

	var alignment := velocity.normalized().dot(offset.normalized())
	var crossed_zero := _has_last_alignment and signf(alignment) != signf(_last_alignment)
	_last_alignment = alignment
	_has_last_alignment = true

	if absf(alignment) <= perpendicular_tolerance or crossed_zero:
		_attach_player(_detected_player)


func _attach_player(player: Player) -> void:
	activate_toward(player.global_position)
	_pendulum_angle = _direction.angle() - Vector2.DOWN.angle()
	_angular_velocity = player.linear_velocity.dot(_get_tangent()) / _rope_length
	_attached_player = player
	area_animation.visible = false
	player.attach_to(get_endpoint_global_position())
	player.set_carried_velocity(_get_tangential_velocity())
	set_physics_process(true)
	player_entered.emit(player)
	player_attached.emit(player)


func _get_tangent() -> Vector2:
	return _direction.rotated(PI / 2.0)


func _get_tangential_velocity() -> Vector2:
	return _get_tangent() * _angular_velocity * _rope_length


func _get_gravity() -> float:
	return float(ProjectSettings.get_setting("physics/2d/default_gravity")) * gravity_multiplier


func _cleanup_attachment() -> void:
	_attached_player = null
	_detected_player = null
	area_animation.visible = true
	set_physics_process(false)
	deactivate()


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body != _detected_player or _attached_player != null:
		return

	var player := _detected_player
	_detected_player = null
	set_physics_process(false)
	deactivate()
	player_exited.emit(player)


func _draw() -> void:
	if not _active:
		return

	var endpoint := _direction * _rope_length
	var segment_count := maxi(int(_rope_length / SEGMENT_LENGTH), 2)
	var dir := _direction
	var perp := dir.rotated(PI / 2.0)

	var points := PackedVector2Array()
	for i in range(segment_count + 1):
		var t := float(i) / segment_count
		var base_pos := endpoint * t
		var wave: float = sin(t * TAU * WAVE_CYCLES) * WAVE_AMPLITUDE * (1.0 - absf(2.0 * t - 1.0))
		points.append(base_pos + perp * wave)

	draw_polyline(points, rope_color, width, true)

	var darker := rope_color.darkened(0.3)
	for i in range(segment_count + 1):
		if i % KNOT_INTERVAL == 0 and i > 0 and i < segment_count:
			draw_circle(points[i], KNOT_RADIUS, darker)
