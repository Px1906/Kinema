class_name AudioController
extends Node

const LAUNCH_SFX := preload("res://audio/sfx/player/launch.wav")
const SURFACE_HIT_SFX := preload("res://audio/sfx/player/object-hiting.ogg")
const ROPE_SFX := preload("res://audio/sfx/player/rope-attached.wav")
const QTE_ACTIVATE_SFX := preload("res://audio/sfx/qte/activate-qte.wav")
const QTE_COUNTDOWN_SFX := preload("res://audio/sfx/qte/contagem-regressiva.wav")
const CHECKPOINT_JINGLE := preload("res://audio/jingles/checkpoint.wav")
const LEVEL_COMPLETE_JINGLE := preload("res://audio/jingles/level-complete.wav")
const GAME_OVER_JINGLE := preload("res://audio/jingles/game-over.wav")

const SURFACE_HIT_SPEED_REF := 300.0

@export_category("Nodes")
@export var player: Player
@export var level_controller: LevelController
@export var goal_zone: GoalZone

@export_category("Volume Balance (dB)")
@export_range(-40.0, 6.0, 0.5) var launch_db := -3.0
@export_range(-40.0, 6.0, 0.5) var surface_hit_db_min := -19.0
@export_range(-40.0, 6.0, 0.5) var surface_hit_db_max := -5.0
@export_range(-40.0, 6.0, 0.5) var rope_db := -1.0
@export_range(-40.0, 6.0, 0.5) var qte_activate_db := -3.0
@export_range(-40.0, 6.0, 0.5) var qte_countdown_db := -3.0
@export_range(-40.0, 6.0, 0.5) var checkpoint_db := -4.0
@export_range(-40.0, 6.0, 0.5) var level_complete_db := 0.0
@export_range(-40.0, 6.0, 0.5) var game_over_db := -2.0


func _ready() -> void:
	if player != null:
		player.launched.connect(_on_player_launched)
		player.surface_collided.connect(_on_surface_collided)
	if level_controller != null:
		level_controller.attempt_failed.connect(_on_attempt_failed)
	if goal_zone != null:
		goal_zone.level_completed.connect(_on_level_completed)
	call_deferred("_connect_ropes")
	call_deferred("_connect_checkpoints")
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
	SFXPool.play(LAUNCH_SFX, launch_db)


func _on_surface_collided(impact_speed: float) -> void:
	var t := clampf(impact_speed / SURFACE_HIT_SPEED_REF, 0.0, 1.0)
	var volume := lerpf(surface_hit_db_min, surface_hit_db_max, t)
	SFXPool.play_random_pitch(SURFACE_HIT_SFX, 0.85, 1.15, volume)


func _on_attempt_failed(_reason: LevelController.FailureReason) -> void:
	SFXPool.play(GAME_OVER_JINGLE, game_over_db)


func _on_level_completed(_player: Player) -> void:
	SFXPool.play(LEVEL_COMPLETE_JINGLE, level_complete_db)


func _on_checkpoint_reached(_checkpoint: CheckpointZone) -> void:
	SFXPool.play(CHECKPOINT_JINGLE, checkpoint_db)


func _on_rope_attached(_player: Player) -> void:
	SFXPool.play(ROPE_SFX, rope_db)


func _on_rope_detached(_player: Player) -> void:
	SFXPool.play(ROPE_SFX, rope_db)


func _on_qte_started(_barrier: QteBarrier) -> void:
	SFXPool.play(QTE_ACTIVATE_SFX, qte_activate_db)


func _on_qte_finished(_barrier: QteBarrier, correct: bool) -> void:
	if not correct:
		SFXPool.play(QTE_COUNTDOWN_SFX, qte_countdown_db)
