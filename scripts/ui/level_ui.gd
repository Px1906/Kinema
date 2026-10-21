class_name LevelUI
extends CanvasLayer

@export var player: Player
@export var launch_controller: LaunchInputController
@export var controls: LaunchControls
@export var attributes: BallAttributes


func _enter_tree() -> void:
	# _enter_tree roda antes do _ready dos filhos, que já precisam das referências.
	if controls == null:
		push_warning("LevelUI: assign the 'Controls' property in the Inspector.")
	else:
		controls.player = player
		controls.launch_controller = launch_controller

	if attributes == null:
		push_warning("LevelUI: assign the 'Attributes' property in the Inspector.")
	else:
		attributes.player = player
