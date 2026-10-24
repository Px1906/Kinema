@tool
class_name QteBarrier
extends StaticBody2D
## @tool só para o editor mostrar size e trigger_distance ao vivo; a lógica de jogo
## é protegida por Engine.is_editor_hint().

const GROUP := &"qte_barrier"
const BARRIER_COLOR := Color("#f59e0b")
const BARRIER_TRIGGERED_COLOR := Color("#f59e0b", 0.5)

@export_category("Barrier")
@export var size: Vector2 = Vector2(32.0, 128.0):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		if is_node_ready():
			_update_collision_shape()
			_update_trigger_shape()
			queue_redraw()

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

## Altura da área de gatilho. Em 0, usa o dobro da altura da barreira.
@export var trigger_height: float = 0.0:
	set(value):
		trigger_height = maxf(value, 0.0)
		if is_node_ready():
			_update_trigger_shape()

var _active := true
var _triggered := false

@onready var barrier_shape: CollisionShape2D = $BarrierShape
@onready var trigger_area: Area2D = $TriggerArea
@onready var trigger_shape: CollisionShape2D = $TriggerArea/TriggerShape


func _ready() -> void:
	_update_collision_shape()
	_update_trigger_shape()
	queue_redraw()
	if Engine.is_editor_hint():
		return

	add_to_group(GROUP)
	trigger_area.body_entered.connect(_on_trigger_body_entered)


func is_active() -> bool:
	return _active


func remove_barrier() -> void:
	_active = false
	barrier_shape.set_deferred("disabled", true)
	trigger_area.set_deferred("monitoring", false)
	queue_redraw()


func reset_barrier() -> void:
	_active = true
	_triggered = false
	barrier_shape.set_deferred("disabled", false)
	trigger_area.set_deferred("monitoring", true)
	queue_redraw()


func _on_trigger_body_entered(body: Node2D) -> void:
	if not _active or _triggered:
		return
	if body is Player:
		_triggered = true
		queue_redraw()
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


func _update_trigger_shape() -> void:
	if trigger_shape == null:
		return
	var height := trigger_height if trigger_height > 0.0 else size.y * 2.0
	_ensure_rect_shape(trigger_shape).size = Vector2(trigger_distance, height)
	trigger_shape.position = Vector2(-trigger_distance / 2.0 - size.x / 2.0, 0.0)


func _draw() -> void:
	if not _active:
		return
	var bounds := Rect2(-size / 2.0, size)
	draw_rect(bounds, BARRIER_TRIGGERED_COLOR if _triggered else BARRIER_COLOR)
