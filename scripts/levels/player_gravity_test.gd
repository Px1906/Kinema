extends Node2D

signal attempt_failed(reason: FailureReason)

enum FailureReason { OBSTACLE_HIT, PLAYER_STOPPED, OUT_OF_BOUNDS }

@export_category("Attempt")
@export var bounds_margin: float = 64.0

@onready var player: Player = $Player
@onready var goal_zone: GoalZone = get_node_or_null("GoalZone")
@onready var rope: Rope = get_node_or_null("Rope")
@onready var controls: LaunchControls = get_node_or_null("LaunchControlSliders")
@onready var result_panel: CanvasLayer = get_node_or_null("AttemptResultPanel")

var _attempt_active := false
var _attempt_finished := false


func _ready() -> void:
	player.launched.connect(_on_player_launched)
	player.obstacle_hit.connect(_on_player_obstacle_hit)
	player.stopped.connect(_on_player_stopped)
	if goal_zone != null:
		goal_zone.level_completed.connect(_on_level_completed)
	if result_panel != null:
		result_panel.connect("retry_requested", _on_retry_requested)
	if controls != null:
		controls.rope = rope


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
	_fail_attempt(FailureReason.PLAYER_STOPPED)


func _on_level_completed(_player: Player) -> void:
	_attempt_finished = true
	_attempt_active = false
	print_debug("PlayerGravityTest: goal reached; level completed.")
	if result_panel != null:
		result_panel.call("show_result", "Fase concluída", "Você alcançou o objetivo.")


func reset_level() -> void:
	_attempt_active = false
	_attempt_finished = true
	if goal_zone != null:
		goal_zone.reset_zone()
	player.reset_attempt(player.get_initial_global_position())
	_attempt_finished = false


func _on_retry_requested() -> void:
	get_tree().reload_current_scene()


func _fail_attempt(reason: FailureReason) -> void:
	if _attempt_finished:
		return

	_attempt_finished = true
	_attempt_active = false
	print_debug("PlayerGravityTest: attempt failed: %s." % FailureReason.keys()[reason])
	attempt_failed.emit(reason)
	if result_panel != null:
		result_panel.call("show_result", "Tentativa perdida", "A bola não alcançou o objetivo.")
