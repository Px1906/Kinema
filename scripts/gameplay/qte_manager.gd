class_name QteManager
extends Node

signal qte_finished(barrier: QteBarrier, correct: bool)
signal time_updated(time_remaining: float)

const DEFAULT_DURATION := 30.0
const SLOW_MOTION_SCALE := 0.1

@export var qte_duration: float = DEFAULT_DURATION

var _active := false
var _current_barrier: QteBarrier = null
var _time_remaining := 0.0
var _original_time_scale := 1.0


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if not _active:
		return

	_time_remaining -= delta / Engine.time_scale
	time_updated.emit(_time_remaining)

	if _time_remaining <= 0.0:
		_time_remaining = 0.0
		_on_timeout()


func is_active() -> bool:
	return _active


func get_current_barrier() -> QteBarrier:
	return _current_barrier


func get_time_remaining() -> float:
	return _time_remaining


func start_qte(barrier: QteBarrier) -> void:
	if _active:
		return

	_active = true
	_current_barrier = barrier
	_time_remaining = qte_duration
	_original_time_scale = Engine.time_scale
	Engine.time_scale = SLOW_MOTION_SCALE
	set_process(true)


func answer(correct: bool) -> void:
	if not _active:
		return

	_end_qte()
	Events.qte_answered.emit(_current_barrier, correct)
	qte_finished.emit(_current_barrier, correct)


func _on_timeout() -> void:
	_end_qte()
	Events.qte_timeout.emit(_current_barrier)
	qte_finished.emit(_current_barrier, false)


func _end_qte() -> void:
	_active = false
	set_process(false)
	Engine.time_scale = _original_time_scale
