@tool
class_name LevelController
extends Node2D
## @tool só para desenhar a margem de bounds_rect no editor; a lógica de jogo é
## protegida por Engine.is_editor_hint().

signal attempt_failed(reason: FailureReason)

enum FailureReason { OBSTACLE_HIT, OUT_OF_BOUNDS }

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const BOUNDS_MARGIN_COLOR := Color(1.0, 0.4, 0.4, 0.6)
const BOUNDS_LINE_WIDTH := 2.0
const BOUNDS_DASH_LENGTH := 8.0

@export_category("Attempt")
## Folga além dos limites da fase antes de a bola contar como fora da fase.
## No editor, aparece como o retângulo tracejado vermelho.
@export var bounds_margin: float = 64.0:
	set(value):
		bounds_margin = value
		queue_redraw()
## Área da fase: redimensione este ReferenceRect com as alças na viewport do editor.
## É a única fonte do tamanho da fase: define quando a bola sai da fase
## (OUT_OF_BOUNDS) e os limites da câmera. Só aparece no editor.
@export var bounds_rect: ReferenceRect:
	set(value):
		_set_bounds_rect_watched(false)
		bounds_rect = value
		_set_bounds_rect_watched(true)
		queue_redraw()

@export_category("Nodes")
@export var goal_zone: GoalZone
## Câmera da fase. Recebe level_bounds como limites para não mostrar fora da fase.
@export var camera: FollowCamera
@export var player: Player
## Opcional. Sem painel, a bola volta direto ao último checkpoint ao falhar.
@export var result_panel: AttemptResultPanel
## Opcional. Sem menu de pausa, a fase não pode ser pausada.
@export var pause_menu: PauseMenu

## Limites da fase em coordenadas do mundo, lidos de bounds_rect no _ready.
var level_bounds := Rect2()
var _attempt_active := false
var _attempt_finished := false
var _checkpoints: Array[CheckpointZone] = []
var _last_checkpoint: CheckpointZone = null
var _height_reference: HeightReference


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_find_unassigned_nodes()
	if bounds_rect != null:
		level_bounds = bounds_rect.get_global_rect()
		# O retângulo é só referência do editor; no jogo não pode bloquear cliques.
		bounds_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not level_bounds.has_area():
		push_warning(
			"LevelController: defina 'Bounds Rect'; usando o retângulo da tela em (0, 0)."
		)
		level_bounds = get_viewport_rect()
	_apply_camera_limits()

	player.launched.connect(_on_player_launched)
	player.state_changed.connect(_on_player_state_changed)
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
	Events.qte_finished.connect(_on_qte_finished)
	_discover_checkpoints()
	_height_reference = (
		get_tree().get_first_node_in_group(HeightReference.GROUP) as HeightReference
	)


## Fases que não herdam de base_level.tscn não ligam esses nós no Inspector;
## nelas, eles são filhos diretos da raiz com o nome padrão.
func _find_unassigned_nodes() -> void:
	if player == null:
		player = get_node_or_null("Player") as Player
	if result_panel == null:
		result_panel = get_node_or_null("AttemptResultPanel") as AttemptResultPanel
	if pause_menu == null:
		pause_menu = get_node_or_null("PauseMenu") as PauseMenu


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _attempt_active or _attempt_finished:
		return

	var bounds := level_bounds.grow(bounds_margin)
	if not bounds.has_point(player.global_position):
		_respawn_at_last_checkpoint()


## O ReferenceRect já desenha a própria borda; aqui só entra a margem de saída.
## O retângulo é em coordenadas do mundo, então desfaz a transformação da raiz.
func _draw() -> void:
	if not Engine.is_editor_hint() or bounds_rect == null:
		return

	draw_set_transform_matrix(global_transform.affine_inverse())
	_draw_dashed_rect(bounds_rect.get_global_rect().grow(bounds_margin), BOUNDS_MARGIN_COLOR)


## No editor, redesenha a margem enquanto o retângulo é arrastado ou redimensionado.
func _set_bounds_rect_watched(watched: bool) -> void:
	if not Engine.is_editor_hint() or bounds_rect == null:
		return
	if bounds_rect.item_rect_changed.is_connected(queue_redraw) == watched:
		return

	if watched:
		bounds_rect.item_rect_changed.connect(queue_redraw)
	else:
		bounds_rect.item_rect_changed.disconnect(queue_redraw)


func _draw_dashed_rect(rect: Rect2, color: Color) -> void:
	var corners := [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]
	for i in corners.size():
		draw_dashed_line(
			corners[i], corners[(i + 1) % corners.size()], color, BOUNDS_LINE_WIDTH, BOUNDS_DASH_LENGTH
		)


func _on_player_launched(_velocity: Vector2) -> void:
	if camera != null:
		camera.follow_target()
	_attempt_active = true
	_attempt_finished = false


## Arrastar a câmera só faz sentido enquanto o jogador estuda a fase antes de lançar.
func _on_player_state_changed(state: Player.State) -> void:
	if camera != null:
		camera.pan_enabled = state == Player.State.READY
	if _height_reference != null:
		_height_reference.drag_enabled = player.can_launch()


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
		result_panel.show_result("Fase completa", "Você chegou à meta!")


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
	_reset_qte_barriers(true)
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
	SceneLoader.go_to(get_tree(), MAIN_MENU_SCENE)


func _save_progress() -> void:
	var current_scene_path: String = scene_file_path
	if current_scene_path.is_empty():
		current_scene_path = get_tree().current_scene.scene_file_path
	(
		SaveManager
		. save_progress(
			{
				"current_level": current_scene_path,
				# "last_checkpoint": _last_checkpoint.checkpoint_index if _last_checkpoint != null else -1,
			}
		)
	)


static func resume_game(tree: SceneTree) -> bool:
	var progress: Dictionary = SaveManager.load_progress()
	var level_path: String = progress.get("current_level", "")
	if level_path.is_empty():
		return false
	# var checkpoint_index: int = int(progress.get("last_checkpoint", -1))
	if not SceneLoader.go_to(tree, level_path):
		return false
	# Após o merge com feat/sistema-checkpoint, restaurar posição:
	# _restore_checkpoint(checkpoint_index)
	return true


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
			return "A bola bateu em um obstáculo."
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
	for barrier: QteBarrier in get_tree().get_nodes_in_group(QteBarrier.GROUP):
		barrier.confirm_removal()
	if pause_menu != null:
		pause_menu.has_checkpoint = true
	print_debug("LevelController: checkpoint %d alcançado." % checkpoint.checkpoint_index)


func _detach_rope() -> void:
	var rope := Rope.get_attached_rope(get_tree())
	if rope != null:
		rope.detach_player()


func _cancel_active_qte() -> void:
	var overlay := get_tree().get_first_node_in_group(QteOverlay.GROUP) as QteOverlay
	if overlay != null:
		overlay.cancel_qte()


## Com full = true (reinício da fase), restaura também as barreiras já confirmadas.
func _reset_qte_barriers(full: bool = false) -> void:
	for barrier: QteBarrier in get_tree().get_nodes_in_group(QteBarrier.GROUP):
		barrier.reset_barrier(full)


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
