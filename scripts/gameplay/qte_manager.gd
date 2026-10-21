class_name QteManager
extends Node

signal time_updated(time_remaining: float)

var qte_duration := 30.0
var slow_motion_scale := 0.1

var _active := false
var _current_barrier: QteBarrier = null
var _time_remaining := 0.0
var _original_time_scale := 1.0
var _start_msec := 0


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	if not _active:
		return

	var elapsed := (Time.get_ticks_msec() - _start_msec) / 1000.0
	_time_remaining = maxf(qte_duration - elapsed, 0.0)
	time_updated.emit(_time_remaining)

	if _time_remaining <= 0.0:
		_on_timeout()


func _exit_tree() -> void:
	if _active:
		Engine.time_scale = _original_time_scale


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
	_original_time_scale = Engine.time_scale
	Engine.time_scale = slow_motion_scale
	_start_msec = Time.get_ticks_msec()
	_time_remaining = qte_duration
	set_process(true)


func answer(correct: bool) -> void:
	if not _active:
		return

	var barrier := _current_barrier
	_end_qte()
	Events.qte_finished.emit(barrier, correct)


func cancel() -> void:
	if not _active:
		return
	_end_qte()


func _on_timeout() -> void:
	var barrier := _current_barrier
	_end_qte()
	Events.qte_finished.emit(barrier, false)


func _end_qte() -> void:
	_active = false
	_current_barrier = null
	set_process(false)
	Engine.time_scale = _original_time_scale
