class_name LevelUI
extends CanvasLayer
## Camada de UI da fase: fica por cima do jogo e não se move com a câmera.
## A fase instancia esta cena e atribui player e launch_controller uma vez só;
## esta camada repassa as referências para os controles antes do _ready deles.

@export var player: Player
@export var launch_controller: LaunchInputController
@export var controls: LaunchControls


func _enter_tree() -> void:
	# _enter_tree roda antes do _ready dos filhos, que já precisam das referências.
	if controls == null:
		push_warning("LevelUI: assign the 'Controls' property in the Inspector.")
		return

	controls.player = player
	controls.launch_controller = launch_controller
