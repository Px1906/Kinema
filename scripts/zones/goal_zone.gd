class_name GoalZone
extends Zone

signal level_completed(player: Player)

var _completed := false


func _ready() -> void:
	super._ready()
	player_entered.connect(_on_player_entered)


func _on_player_entered(player: Player) -> void:
	if _completed:
		return

	_completed = true
	level_completed.emit(player)
