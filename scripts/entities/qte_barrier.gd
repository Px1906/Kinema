@tool
class_name QteBarrier
extends StaticBody2D
## @tool só para o editor mostrar size e trigger_distance ao vivo; a lógica de jogo
## é protegida por Engine.is_editor_hint().

const GROUP := &"qte_barrier"
## Valor de trigger_height que pede a altura automática.
const TRIGGER_HEIGHT_AUTO := -1.0
## Na altura automática, o gatilho tem esta proporção da altura da barreira.
const DEFAULT_TRIGGER_HEIGHT_FACTOR := 2.0
## Animações do sprite: arte em pé e deitada, ambas com os "?" na vertical.
const ANIM_VERTICAL := &"vertical"
const ANIM_HORIZONTAL := &"horizontal"

@export_category("Barrier")
@export var size: Vector2 = Vector2(32.0, 128.0):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		if is_node_ready():
			_update_collision_shape()
			_update_trigger_shape()

@export_category("Question")
## Conteúdo das perguntas desta barreira (campo "content" em qte_questions.json).
## Vazio sorteia entre todas as perguntas.
@export_enum("energia_cinetica", "energia_potencial", "conservacao_energia", "corda", "lancamento")
var content: String = ""

@export_category("Trigger")
@export var trigger_distance: float = 200.0:
	set(value):
		trigger_distance = maxf(value, 1.0)
		if is_node_ready():
			_update_trigger_shape()

## Altura da área de gatilho. Negativo (-1) usa DEFAULT_TRIGGER_HEIGHT_FACTOR × a altura
## da barreira.
@export var trigger_height: float = TRIGGER_HEIGHT_AUTO:
	set(value):
		trigger_height = TRIGGER_HEIGHT_AUTO if value < 0.0 else maxf(value, 1.0)
		if is_node_ready():
			_update_trigger_shape()

var _active := true
var _triggered := false
var _cleared := false

@onready var barrier_shape: CollisionShape2D = $BarrierShape
@onready var trigger_area: Area2D = $TriggerArea
@onready var trigger_shape: CollisionShape2D = $TriggerArea/TriggerShape
@onready var _sprite: AnimatedSprite2D = $BarrierShape/AnimatedSprite2D


func _ready() -> void:
	_update_collision_shape()
	_update_trigger_shape()
	_update_sprite()
	# Recalcula o sprite quando a barreira é girada/espelhada (inclusive no editor).
	set_notify_transform(true)
	if Engine.is_editor_hint():
		return

	add_to_group(GROUP)
	trigger_area.body_entered.connect(_on_trigger_body_entered)
	if _sprite != null:
		_sprite.play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_sprite()


func is_active() -> bool:
	return _active


func remove_barrier() -> void:
	_active = false
	barrier_shape.set_deferred("disabled", true)
	trigger_area.set_deferred("monitoring", false)
	if _sprite != null:
		_sprite.visible = false


## Torna definitiva a remoção de uma barreira já respondida: voltar ao checkpoint
## não a traz de volta. Só reset_barrier(true) a restaura.
func confirm_removal() -> void:
	if not _active:
		_cleared = true


## Com full = false, barreiras confirmadas por confirm_removal() continuam removidas.
func reset_barrier(full: bool = false) -> void:
	if _cleared and not full:
		return
	_cleared = false
	_active = true
	_triggered = false
	barrier_shape.set_deferred("disabled", false)
	trigger_area.set_deferred("monitoring", true)
	if _sprite != null:
		_sprite.visible = true


func _on_trigger_body_entered(body: Node2D) -> void:
	if not _active or _triggered:
		return
	if body is Player:
		_triggered = true
		Events.qte_started.emit(self)


func _ensure_rect_shape(col: CollisionShape2D) -> RectangleShape2D:
	var rect := col.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		col.shape = rect
	return rect


func _update_collision_shape() -> void:
	if barrier_shape == null:
		return
	_ensure_rect_shape(barrier_shape).size = size
	_update_sprite()


func _update_trigger_shape() -> void:
	if trigger_shape == null:
		return
	var height := trigger_height
	if trigger_height == TRIGGER_HEIGHT_AUTO:
		height = size.y * DEFAULT_TRIGGER_HEIGHT_FACTOR
	_ensure_rect_shape(trigger_shape).size = Vector2(trigger_distance, height)
	trigger_shape.position = Vector2(-trigger_distance / 2.0 - size.x / 2.0, 0.0)


## Desenha o sprite sempre "em pé" no mundo: ignora rotação e espelhamento da
## barreira (para os "?" não ficarem de cabeça para baixo) e escolhe a arte
## vertical ou horizontal conforme a forma da barreira na tela.
func _update_sprite() -> void:
	if _sprite == null or barrier_shape == null or not is_inside_tree():
		return
	var xf := barrier_shape.global_transform
	# Caixa envolvente (no mundo) do retângulo de colisão; exata para rotações
	# múltiplas de 90°.
	var x_axis := xf.x * size.x
	var y_axis := xf.y * size.y
	var world_size := Vector2(
		absf(x_axis.x) + absf(y_axis.x), absf(x_axis.y) + absf(y_axis.y)
	)
	var anim := ANIM_HORIZONTAL if world_size.x > world_size.y else ANIM_VERTICAL
	if _sprite.animation != anim:
		_sprite.animation = anim
	var frame_tex := _sprite.sprite_frames.get_frame_texture(anim, 0)
	if frame_tex == null:
		return
	_sprite.global_transform = Transform2D(0.0, world_size / frame_tex.get_size(), 0.0, xf.origin)
