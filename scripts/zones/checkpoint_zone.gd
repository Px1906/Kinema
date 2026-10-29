class_name CheckpointZone
extends Zone

signal checkpoint_reached(checkpoint: CheckpointZone)

const GROUP := &"checkpoint"
const FLAG_COLOR_REACHED := Color(0.13, 0.77, 0.37)

@export var checkpoint_index: int = 0

@export_category("Magnet")
@export var pull_duration: float = 0.45
@export var pull_velocity_influence: float = 0.12

var _reached := false

@onready var _bandeira_sprite: AnimatedSprite2D = $BandeiraSprite


func _ready() -> void:
	super._ready()
	add_to_group(GROUP)
	player_entered.connect(_on_player_entered)


func reach() -> void:
	if _reached:
		return
	_reached = true
	if _bandeira_sprite != null and _bandeira_sprite.material is ShaderMaterial:
		(_bandeira_sprite.material as ShaderMaterial).set_shader_parameter("flag_color", FLAG_COLOR_REACHED)
	checkpoint_reached.emit(self)


func reset_zone() -> void:
	_reached = false
	if _bandeira_sprite != null and _bandeira_sprite.material is ShaderMaterial:
		(_bandeira_sprite.material as ShaderMaterial).set_shader_parameter("flag_color", Color.BLACK)


func _on_player_entered(player: Player) -> void:
	if _reached:
		return
	_pull_and_reach.call_deferred(player)


func _pull_and_reach(player: Player) -> void:
	if _reached or not is_instance_valid(player):
		return
	if player.pull_to(global_position, pull_duration, pull_velocity_influence):
		reach()
