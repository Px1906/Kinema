class_name FollowCamera
extends Camera2D
## Câmera que segue o alvo (normalmente o Player) usando a suavização nativa do Camera2D.
## Quando o alvo é teleportado (ex.: reset da tentativa), a câmera pula junto em vez de deslizar.
## Use os limites do Camera2D (Limit no Inspector) para não mostrar fora da fase.

@export var target: Node2D
## Distância em px que o alvo precisa pular em um único frame para ser tratado como teleporte.
@export var teleport_distance: float = 256.0

var _last_target_position := Vector2.ZERO


func _ready() -> void:
	if target == null:
		push_warning("FollowCamera: assign the 'Target' property in the Inspector.")
		set_process(false)
		return

	_snap_to_target()


func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		return

	var target_position := target.global_position
	global_position = target_position
	if _last_target_position.distance_to(target_position) > teleport_distance:
		reset_smoothing()
	_last_target_position = target_position


func _snap_to_target() -> void:
	global_position = target.global_position
	_last_target_position = global_position
	reset_smoothing()
