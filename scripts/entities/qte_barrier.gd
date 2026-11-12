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
	if Engine.is_editor_hint():
		return

	add_to_group(GROUP)
	trigger_area.body_entered.connect(_on_trigger_body_entered)
	if _sprite != null:
		_sprite.play()


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


func _update_sprite() -> void:
	if _sprite == null:
		return
	var frame_tex := _sprite.sprite_frames.get_frame_texture(&"default", 0)
	if frame_tex == null:
		return
	var tex_size := frame_tex.get_size()
	_sprite.scale = Vector2(size.x / tex_size.x, size.y / tex_size.y)
	_sprite.position = Vector2.ZERO
