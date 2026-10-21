class_name LevelController
extends Node2D

signal attempt_failed(reason: FailureReason)

enum FailureReason { OBSTACLE_HIT, OUT_OF_BOUNDS }

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@export_category("Attempt")
@export var bounds_margin: float = 64.0
## Área da fase em coordenadas do mundo. É a única fonte do tamanho da fase: define
## quando a bola sai da fase (OUT_OF_BOUNDS) e os limites da câmera.
@export var level_bounds := Rect2()

@export_category("Nodes")
@export var controls: LaunchControls
@export var goal_zone: GoalZone
## Câmera da fase. Recebe level_bounds como limites para não mostrar fora da fase.
@export var camera: FollowCamera
@export var player: Player
## Opcional. A corda da fase, também usada pelos controles de lançamento.
@export var rope: Rope
## Opcional. Sem painel, a bola volta direto ao último checkpoint ao falhar.
@export var result_panel: AttemptResultPanel
## Opcional. Sem menu de pausa, a fase não pode ser pausada.
@export var pause_menu: PauseMenu

var _attempt_active := false
var _attempt_finished := false
var _checkpoints: Array[CheckpointZone] = []
var _last_checkpoint: CheckpointZone = null


func _ready() -> void:
	_find_unassigned_nodes()
	if not level_bounds.has_area():
		push_warning(
			"LevelController: defina 'Level Bounds'; usando o retângulo da tela em (0, 0)."
		)
		level_bounds = get_viewport_rect()
	_apply_camera_limits()

	player.launched.connect(_on_player_launched)
	player.obstacle_hit.connect(_on_player_obstacle_hit)
	player.stopped.connect(_on_player_stopped)
	if goal_zone != null:
		goal_zone.level_completed.connect(_on_level_completed)
	if result_panel != null:
		result_panel.retry_requested.connect(_on_retry_requested)
		result_panel.exit_requested.connect(_on_exit_requested)
	if pause_menu != null:
		pause_menu.restart_full_requested.connect(reset_level)
		pause_menu.restart_checkpoint_requested.connect(_respawn_at_last_checkpoint)
		pause_menu.exit_requested.connect(_on_exit_requested)
	if controls != null:
		controls.rope = rope
	Events.qte_finished.connect(_on_qte_finished)
	_discover_checkpoints()


## Fases que não herdam de base_level.tscn não ligam esses nós no Inspector;
## nelas, eles são filhos diretos da raiz com o nome padrão.
func _find_unassigned_nodes() -> void:
	if player == null:
		player = get_node_or_null("Player") as Player
	if rope == null:
		rope = get_node_or_null("Rope") as Rope
	if result_panel == null:
		result_panel = get_node_or_null("AttemptResultPanel") as AttemptResultPanel
	if pause_menu == null:
		pause_menu = get_node_or_null("PauseMenu") as PauseMenu


func _process(_delta: float) -> void:
	if not _attempt_active or _attempt_finished:
		return

	var bounds := level_bounds.grow(bounds_margin)
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
	_cancel_active_qte()
	_attempt_finished = true
	_attempt_active = false
	_save_progress()
	print_debug("LevelController: goal reached; level completed.")
	if result_panel != null:
		result_panel.show_result("Fase concluída", "Você alcançou o objetivo.")


func reset_level() -> void:
	_cancel_active_qte()
	_detach_rope()
	_attempt_active = false
	_attempt_finished = true
	_last_checkpoint = null
	for cp in _checkpoints:
		cp.reset_zone()
	if goal_zone != null:
		goal_zone.reset_zone()
	_reset_qte_barriers()
	if pause_menu != null:
		pause_menu.has_checkpoint = false
	player.reset_attempt(player.get_initial_global_position())
	if camera != null:
		camera.snap_to_target()
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
	assert(not current_scene_path.is_empty(), "LevelController: scene_file_path is empty.")
	if current_scene_path.is_empty():
		push_warning("LevelController: could not determine current scene path, skipping save.")
		return
	SaveManager.save_progress({
		"current_level": current_scene_path,
	})


func _on_qte_finished(barrier: QteBarrier, correct: bool) -> void:
	if correct:
		barrier.remove_barrier()


func _fail_attempt(reason: FailureReason) -> void:
	if _attempt_finished:
		return

	_cancel_active_qte()
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
		_:
			return "Tente novamente."


func _respawn_at_last_checkpoint() -> void:
	_cancel_active_qte()
	_detach_rope()
	_attempt_active = false
	_attempt_finished = false
	_reset_qte_barriers()
	player.reset_attempt(get_respawn_position())
	if camera != null:
		camera.snap_to_target()


func _discover_checkpoints() -> void:
	for child: Node in _get_all_descendants(self):
		if child is CheckpointZone:
			_checkpoints.append(child)
			child.checkpoint_reached.connect(_on_checkpoint_reached)
	_checkpoints.sort_custom(
		func(a: CheckpointZone, b: CheckpointZone) -> bool:
			return a.checkpoint_index < b.checkpoint_index
	)


func _on_checkpoint_reached(checkpoint: CheckpointZone) -> void:
	_last_checkpoint = checkpoint
	if pause_menu != null:
		pause_menu.has_checkpoint = true
	print_debug("LevelController: checkpoint %d alcançado." % checkpoint.checkpoint_index)


func _detach_rope() -> void:
	if rope != null and rope.is_player_attached():
		rope.detach_player()


func _cancel_active_qte() -> void:
	var overlay := get_tree().get_first_node_in_group(QteOverlay.GROUP) as QteOverlay
	if overlay != null:
		overlay.cancel_qte()


func _reset_qte_barriers() -> void:
	for barrier: QteBarrier in get_tree().get_nodes_in_group(QteBarrier.GROUP):
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


func _apply_camera_limits() -> void:
	if camera == null:
		return

	camera.limit_left = floori(level_bounds.position.x)
	camera.limit_top = floori(level_bounds.position.y)
	camera.limit_right = ceili(level_bounds.end.x)
	camera.limit_bottom = ceili(level_bounds.end.y)
