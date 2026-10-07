extends Node2D

@onready var player: Player = $Player


func _ready() -> void:
	var controls := LaunchControls.new()
	controls.player = player
	add_child(controls)
