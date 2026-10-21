class_name CheckpointZone
extends Zone

signal checkpoint_reached(checkpoint: CheckpointZone)

const MARKER_RADIUS := 12.0
const MARKER_WIDTH := 2.0
const COLOR_UNREACHED := Color("#6b7280")
const COLOR_REACHED := Color("#22c55e")
const BRAKE_DAMP := 15.0

@export var checkpoint_index: int = 0

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
	player.apply_brake(BRAKE_DAMP)
	reach()


func _draw() -> void:
	var color := COLOR_REACHED if _reached else COLOR_UNREACHED
	draw_circle(Vector2.ZERO, MARKER_RADIUS, color, false, MARKER_WIDTH)
	if _reached:
		draw_circle(Vector2.ZERO, MARKER_RADIUS * 0.4, color)
