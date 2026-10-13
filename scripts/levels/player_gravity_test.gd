extends Node2D

@onready var player: Player = $Player
@onready var rope: Rope = get_node_or_null("Rope")
@onready var controls: LaunchControls = get_node_or_null("LaunchControlSliders")

func _ready() -> void:
	player.obstacle_hit.connect(_restart_attempt)
	if controls != null:
		controls.rope = rope


func _restart_attempt() -> void:
	player.reset_attempt(player.get_initial_global_position())
