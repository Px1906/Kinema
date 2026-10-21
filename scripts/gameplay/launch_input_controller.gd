class_name LaunchInputController
extends Node

@export var player: Player


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("launch"):
		return

	if Rope.get_attached_rope(get_tree()) != null:
		release()
	else:
		launch()


func launch() -> void:
	if player == null:
		return

	player.launch()


## Solta a bola de qualquer corda da fase que a esteja segurando.
func release() -> void:
	var rope := Rope.get_attached_rope(get_tree())
	if rope == null:
		return

	rope.detach_player()
