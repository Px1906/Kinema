class_name GoalZone
extends Zone

signal level_completed(player: Player)

var _completed := false


func _ready() -> void:
	super._ready()
	player_entered.connect(_on_player_entered)


func reset_zone() -> void:
	_completed = false


func _on_player_entered(player: Player) -> void:
	if _completed:
		return

	_completed = true
	print_debug("GoalZone: player entered; level completed.")
	level_completed.emit(player)
