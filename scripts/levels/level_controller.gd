class_name LevelController
extends Node2D

signal attempt_failed(reason: FailureReason)

enum FailureReason { OBSTACLE_HIT, PLAYER_STOPPED, OUT_OF_BOUNDS }

@export_category("Attempt")
@export var bounds_margin: float = 64.0

@onready var player: Player = $Player
@onready var goal_zone: GoalZone = get_node_or_null("Zones/GoalZone")
@onready var rope: Rope = get_node_or_null("Rope")
@onready var controls: LaunchControls = get_node_or_null("LaunchControlSliders")
@onready var result_panel: AttemptResultPanel = get_node_or_null("AttemptResultPanel")

var _attempt_active := false
var _attempt_finished := false
var _checkpoints: Array[CheckpointZone] = []
var _last_checkpoint: CheckpointZone = null


func _ready() -> void:
	player.launched.connect(_on_player_launched)
	player.obstacle_hit.connect(_on_player_obstacle_hit)
	player.stopped.connect(_on_player_stopped)
	if goal_zone != null:
		goal_zone.level_completed.connect(_on_level_completed)
	if result_panel != null:
		result_panel.retry_requested.connect(_on_retry_requested)
	if controls != null:
		controls.rope = rope
	_discover_checkpoints()


func _process(_delta: float) -> void:
	if not _attempt_active or _attempt_finished:
		return

	var bounds := get_viewport_rect().grow(bounds_margin)
	if not bounds.has_point(player.global_position):
		_fail_attempt(FailureReason.OUT_OF_BOUNDS)


func _on_player_launched(_velocity: Vector2) -> void:
	_attempt_active = true
	_attempt_finished = false


func _on_player_obstacle_hit() -> void:
	_fail_attempt(FailureReason.OBSTACLE_HIT)


func _on_player_stopped() -> void:
	if _attempt_finished:
		return
	_attempt_active = false
	player.prepare_launch()


func _on_level_completed(_player: Player) -> void:
	_attempt_finished = true
	_attempt_active = false
	print_debug("LevelController: goal reached; level completed.")
	if result_panel != null:
		result_panel.show_result("Fase concluída", "Você alcançou o objetivo.")


func reset_level() -> void:
	_attempt_active = false
	_attempt_finished = true
	if goal_zone != null:
		goal_zone.reset_zone()
	player.reset_attempt(player.get_initial_global_position())
	_attempt_finished = false


func _on_retry_requested() -> void:
	_respawn_at_last_checkpoint()


func _fail_attempt(reason: FailureReason) -> void:
	if _attempt_finished:
		return

	_attempt_finished = true
	_attempt_active = false
	print_debug("LevelController: attempt failed: %s." % FailureReason.keys()[reason])
	attempt_failed.emit(reason)
	_respawn_at_last_checkpoint()


func _respawn_at_last_checkpoint() -> void:
	_attempt_active = false
	_attempt_finished = false
	player.reset_attempt(get_respawn_position())


func _discover_checkpoints() -> void:
	for child: Node in _get_all_descendants(self):
		if child is CheckpointZone:
			_checkpoints.append(child)
			child.checkpoint_reached.connect(_on_checkpoint_reached)
	_checkpoints.sort_custom(func(a: CheckpointZone, b: CheckpointZone) -> bool:
		return a.checkpoint_index < b.checkpoint_index
	)


func _on_checkpoint_reached(checkpoint: CheckpointZone) -> void:
	_last_checkpoint = checkpoint
	print_debug("LevelController: checkpoint %d alcançado." % checkpoint.checkpoint_index)


func _get_all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child: Node in node.get_children():
		result.append(child)
		result.append_array(_get_all_descendants(child))
	return result


func get_respawn_position() -> Vector2:
	if _last_checkpoint != null:
		return _last_checkpoint.global_position
	return player.get_initial_global_position()
