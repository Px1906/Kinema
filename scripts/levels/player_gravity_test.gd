extends Node2D

@onready var player: Player = $Player
@onready var rope: Rope = get_node_or_null("Rope")
@onready var controls: LaunchControls = get_node_or_null("LaunchControlSliders")

func _ready() -> void:
	if controls != null:
		controls.rope = rope


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_SPACE:
		if rope != null and rope.is_player_attached():
			rope.detach_player()
		elif controls == null and player.state == Player.State.PREPARANDO:
			player.launch()
