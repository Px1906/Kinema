class_name AudioController
extends Node

@export_category("Nodes")
@export var player: Player
@export var level_controller: LevelController
@export var goal_zone: GoalZone

@export_category("Player SFX")
@export var launch_sound: AudioStream
@export var obstacle_hit_sound: AudioStream
@export var out_of_bounds_sound: AudioStream
@export var checkpoint_sound: AudioStream
@export var level_complete_sound: AudioStream

@export_category("Rope SFX")
@export var rope_attach_sound: AudioStream
@export var rope_release_sound: AudioStream

@export_category("QTE SFX")
@export var qte_activate_sound: AudioStream
@export var qte_timeout_sound: AudioStream


func _ready() -> void:
	if player != null:
		player.launched.connect(_on_player_launched)
		player.obstacle_hit.connect(_on_player_obstacle_hit)
	if level_controller != null:
		level_controller.attempt_failed.connect(_on_attempt_failed)
	if goal_zone != null:
		goal_zone.level_completed.connect(_on_level_completed)
	_connect_ropes()
	_connect_checkpoints()
	Events.qte_started.connect(_on_qte_started)
	Events.qte_finished.connect(_on_qte_finished)


func _connect_ropes() -> void:
	for node: Node in get_tree().get_nodes_in_group(Rope.GROUP):
		var rope := node as Rope
		if rope == null:
			continue
		rope.player_attached.connect(_on_rope_attached)
		rope.player_detached.connect(_on_rope_detached)


func _connect_checkpoints() -> void:
	for node: Node in get_tree().get_nodes_in_group(CheckpointZone.GROUP):
		var checkpoint := node as CheckpointZone
		if checkpoint == null:
			continue
		checkpoint.checkpoint_reached.connect(_on_checkpoint_reached)


func _on_player_launched(_velocity: Vector2) -> void:
	_play(launch_sound)


func _on_player_obstacle_hit() -> void:
	_play(obstacle_hit_sound)


func _on_attempt_failed(reason: LevelController.FailureReason) -> void:
	if reason == LevelController.FailureReason.OUT_OF_BOUNDS:
		_play(out_of_bounds_sound)


func _on_level_completed(_player: Player) -> void:
	_play(level_complete_sound)


func _on_checkpoint_reached(_checkpoint: CheckpointZone) -> void:
	_play(checkpoint_sound)


func _on_rope_attached(_player: Player) -> void:
	_play(rope_attach_sound)


func _on_rope_detached(_player: Player) -> void:
	_play(rope_release_sound)


func _on_qte_started(_barrier: QteBarrier) -> void:
	_play(qte_activate_sound)


func _on_qte_finished(_barrier: QteBarrier, correct: bool) -> void:
	if not correct:
		_play(qte_timeout_sound)


func _play(stream: AudioStream) -> void:
	if stream != null:
		SFXPool.play(stream)
