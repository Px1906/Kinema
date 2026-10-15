class_name LaunchInputController
extends Node

@export var player: Player
@export var rope: Rope


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("launch"):
		return

	if rope != null and rope.is_player_attached():
		release()
	else:
		launch()


func launch() -> void:
	if player == null:
		return

	player.launch()


func release() -> void:
	if rope == null:
		return

	rope.detach_player()
