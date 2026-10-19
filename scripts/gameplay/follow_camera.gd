class_name FollowCamera
extends Camera2D
## Câmera que segue o alvo (normalmente o Player) usando a suavização nativa do Camera2D.
## Não é filha do Player para poder ter limites, zoom e reposicionamento próprios.
## Roda no passo de física, junto com o Player (RigidBody2D), para não tremer.
## Quem teleporta o alvo (ex.: reset da tentativa) chama snap_to_target() para a câmera
## pular junto em vez de deslizar. Os limites vêm do LevelController (level_bounds).

@export var target: Node2D


func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	if not is_instance_valid(target):
		push_warning("FollowCamera: assign the 'Target' property in the Inspector.")
		set_physics_process(false)
		return

	snap_to_target()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		set_physics_process(false)
		return

	global_position = target.global_position


## Move a câmera direto para o alvo, sem a suavização.
func snap_to_target() -> void:
	if not is_instance_valid(target):
		return

	global_position = target.global_position
	reset_smoothing()
