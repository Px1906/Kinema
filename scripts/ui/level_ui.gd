class_name LevelUI
extends CanvasLayer
## Camada de UI da fase: fica por cima do jogo e não se move com a câmera.
## A fase instancia esta cena e atribui player e launch_controller uma vez só;
## esta camada repassa as referências para os controles antes do _ready deles.
## O botão de recentralizar só aparece com a câmera solta (arrastada pelo jogador).

@export var player: Player
@export var launch_controller: LaunchInputController
@export var controls: LaunchControls
@export var attributes: BallAttributes
@export var camera: FollowCamera
@export var recenter_button: Button


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


func _ready() -> void:
	Events.qte_started.connect(_on_qte_started)
	Events.qte_finished.connect(_on_qte_finished)

	if recenter_button == null:
		return

	recenter_button.visible = false
	if camera == null:
		push_warning("LevelUI: assign the 'Camera' property to show the recenter button.")
		return

	recenter_button.pressed.connect(camera.follow_target)
	camera.following_changed.connect(_on_camera_following_changed)
	_on_camera_following_changed(camera.is_following())


func _on_camera_following_changed(is_following: bool) -> void:
	recenter_button.visible = not is_following


func _on_qte_started(_barrier: QteBarrier) -> void:
	if controls != null:
		controls.visible = false
	if attributes != null:
		attributes.visible = false
	if recenter_button != null:
		recenter_button.visible = false


func _on_qte_finished(_barrier: QteBarrier, _correct: bool) -> void:
	if controls != null:
		controls.visible = true
	if attributes != null:
		attributes.visible = true
