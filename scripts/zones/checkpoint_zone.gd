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
var _player_inside := false
var _player_interacted := false


func _ready() -> void:
	super._ready()
	player_entered.connect(_on_player_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func is_reached() -> bool:
	return _reached


func is_player_inside() -> bool:
	return _player_inside


func reach() -> void:
	if _reached:
		return
	_reached = true
	queue_redraw()
	checkpoint_reached.emit(self)


func reset_zone() -> void:
	_reached = false
	_player_inside = false
	_player_interacted = false
	queue_redraw()


func _on_player_entered(player: Player) -> void:
	_player_inside = true
	if _player_interacted:
		return
	_player_interacted = true
	player.apply_brake(BRAKE_DAMP)
	reach()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false


func _draw() -> void:
	var color := COLOR_REACHED if _reached else COLOR_UNREACHED
	draw_circle(Vector2.ZERO, MARKER_RADIUS, color, false, MARKER_WIDTH)
	if _reached:
		draw_circle(Vector2.ZERO, MARKER_RADIUS * 0.4, color)
