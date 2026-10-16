class_name LevelController
extends Node2D

signal attempt_failed(reason: FailureReason)

enum FailureReason { OBSTACLE_HIT, PLAYER_STOPPED, OUT_OF_BOUNDS }

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

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
var _qte_barriers: Array[QteBarrier] = []


func _ready() -> void:
	player.launched.connect(_on_player_launched)
	player.obstacle_hit.connect(_on_player_obstacle_hit)
	player.stopped.connect(_on_player_stopped)
	if goal_zone != null:
		goal_zone.level_completed.connect(_on_level_completed)
	if result_panel != null:
		result_panel.retry_requested.connect(_on_retry_requested)
		result_panel.exit_requested.connect(_on_exit_requested)
	if controls != null:
		controls.rope = rope
	_discover_checkpoints()
	_discover_qte_barriers()


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
	_reset_qte_barriers()
	player.reset_attempt(player.get_initial_global_position())
	_attempt_finished = false


func _on_retry_requested() -> void:
	_respawn_at_last_checkpoint()


func _on_exit_requested() -> void:
	_save_progress()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _save_progress() -> void:
	var current_scene_path: String = scene_file_path
	if current_scene_path.is_empty():
		current_scene_path = get_tree().current_scene.scene_file_path
	SaveManager.save_progress({
		"current_level": current_scene_path,
		# "last_checkpoint": _last_checkpoint.checkpoint_index if _last_checkpoint != null else -1,
	})


static func resume_game(tree: SceneTree) -> bool:
	var progress: Dictionary = SaveManager.load_progress()
	var level_path: String = progress.get("current_level", "")
	if level_path.is_empty() or not ResourceLoader.exists(level_path):
		return false
	# var checkpoint_index: int = int(progress.get("last_checkpoint", -1))
	tree.change_scene_to_file(level_path)
	# Após o merge com feat/sistema-checkpoint, restaurar posição:
	# _restore_checkpoint(checkpoint_index)
	return true


func _fail_attempt(reason: FailureReason) -> void:
	if _attempt_finished:
		return

	_attempt_finished = true
	_attempt_active = false
	print_debug("LevelController: attempt failed: %s." % FailureReason.keys()[reason])
	attempt_failed.emit(reason)
	if result_panel != null:
		result_panel.show_result("Tentativa perdida", _get_failure_message(reason))
	else:
		_respawn_at_last_checkpoint()


func _get_failure_message(reason: FailureReason) -> String:
	match reason:
		FailureReason.OBSTACLE_HIT:
			return "A bola atingiu um obstáculo."
		FailureReason.OUT_OF_BOUNDS:
			return "A bola saiu dos limites."
		FailureReason.PLAYER_STOPPED:
			return "A bola parou fora de um checkpoint."
		_:
			return "Tente novamente."


func _respawn_at_last_checkpoint() -> void:
	_attempt_active = false
	_attempt_finished = false
	_reset_qte_barriers()
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


func _discover_qte_barriers() -> void:
	for child: Node in _get_all_descendants(self):
		if child is QteBarrier:
			_qte_barriers.append(child)


func _reset_qte_barriers() -> void:
	for barrier: QteBarrier in _qte_barriers:
		barrier.reset_barrier()


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
