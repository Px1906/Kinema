extends Node2D

@onready var player: Player = $Player


func _ready() -> void:
	var controls := LaunchControls.new()
	controls.player = player
	add_child(controls)

	var mouse := MouseControl.new()
	mouse.player = player
	mouse.position = Vector2(40, 200)  # canto superior esquerdo da área
	mouse.size = Vector2(300, 300)     # largura e altura
	add_child(mouse)
