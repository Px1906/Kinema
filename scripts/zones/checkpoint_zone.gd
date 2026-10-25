class_name CheckpointZone
extends Zone

signal checkpoint_reached(checkpoint: CheckpointZone)

const MARKER_RADIUS := 12.0
const MARKER_WIDTH := 2.0
const COLOR_UNREACHED := Color("#6b7280")
const COLOR_REACHED := Color("#22c55e")

@export var checkpoint_index: int = 0

@export_category("Magnet")
@export var pull_duration: float = 0.45
## Quanto a velocidade de entrada entorta a curva até o ímã (segundos de "embalo").
@export var pull_velocity_influence: float = 0.12

var _reached := false


func _ready() -> void:
	super._ready()
	player_entered.connect(_on_player_entered)
	queue_redraw()


func reach() -> void:
	if _reached:
		return
	_reached = true
	queue_redraw()
	checkpoint_reached.emit(self)


func reset_zone() -> void:
	_reached = false
	queue_redraw()


func _on_player_entered(player: Player) -> void:
	if _reached:
		return
	# Adiado: congelar o corpo dentro do body_entered falha durante a etapa de física.
	_pull_and_reach.call_deferred(player)


## Só marca o checkpoint se o ímã de fato pegou a bola.
func _pull_and_reach(player: Player) -> void:
	if _reached or not is_instance_valid(player):
		return
	if player.pull_to(global_position, pull_duration, pull_velocity_influence):
		reach()


func _draw() -> void:
	var color := COLOR_REACHED if _reached else COLOR_UNREACHED
	draw_circle(Vector2.ZERO, MARKER_RADIUS, color, false, MARKER_WIDTH)
	if _reached:
		draw_circle(Vector2.ZERO, MARKER_RADIUS * 0.4, color)
