extends Node2D

@onready var player: Player = $Player
@onready var rope: Rope = get_node_or_null("Rope")
@onready var controls: LaunchControls = get_node_or_null("LaunchControlSliders")

func _ready() -> void:
	player.obstacle_hit.connect(_restart_level)
	if controls != null:
		controls.rope = rope


func _restart_level() -> void:
	get_tree().reload_current_scene()
