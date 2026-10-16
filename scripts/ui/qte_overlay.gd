class_name QteOverlay
extends CanvasLayer

signal answer_selected(correct: bool)

const COLOR_CORRECT := Color("#22c55e")
const COLOR_WRONG := Color("#ef4444")
const STYLE_CORNER_RADIUS := 4
const STYLE_CONTENT_MARGIN := 8

@export var player: Player

@export_category("QTE")
@export var qte_duration: float = 30.0
@export_range(0.01, 1.0, 0.01) var slow_motion_scale: float = 0.1

@export_category("Audio")
@export var correct_sound: AudioStream
@export var wrong_sound: AudioStream
@export var audio_bus: StringName = &"SFX"

@export_category("Timing")
@export_range(0.1, 5.0, 0.1) var result_display_time: float = 1.5

@export_category("Animation")
@export_range(0.0, 1.0, 0.05) var vignette_intensity: float = 0.4
@export_range(0.1, 2.0, 0.05) var anim_duration: float = 0.3
@export var anim_slide_offset: float = 100.0

var _qte_manager := QteManager.new()
var _question_generator := QteQuestionGenerator.new()
var _ball_energy: BallEnergy
var _current_correct_index := -1
var _answered := false
var _audio_player: AudioStreamPlayer

@onready var _vignette: ColorRect = %Vignette
@onready var _question_label: Label = %QuestionLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _buttons_container: VBoxContainer = %ButtonsContainer
@onready var _button_a: Button = %ButtonA
@onready var _button_b: Button = %ButtonB
@onready var _button_c: Button = %ButtonC
@onready var _reward_sprite: AnimatedSprite2D = get_node_or_null("%RewardSprite")
@onready var _mass_label: Label = %QteMassValue
@onready var _speed_label: Label = %QteSpeedValue
@onready var _ec_label: Label = %QteEcValue
@onready var _ep_label: Label = %QteEpValue
@onready var _et_label: Label = %QteEtValue


func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = audio_bus
	add_child(_audio_player)

	add_child(_qte_manager)
	_qte_manager.time_updated.connect(_on_time_updated)
	_qte_manager.qte_finished.connect(_on_qte_finished)

	_button_a.pressed.connect(_on_button_pressed.bind(0))
	_button_b.pressed.connect(_on_button_pressed.bind(1))
	_button_c.pressed.connect(_on_button_pressed.bind(2))

	Events.qte_started.connect(_on_qte_started)

	if player != null:
		_ball_energy = _find_ball_energy()

	_hide_overlay()


func _find_ball_energy() -> BallEnergy:
	if player == null:
		return null
	for child in player.get_children():
		if child is BallEnergy:
			return child
	return null


func _on_qte_started(barrier: QteBarrier) -> void:
	if _ball_energy == null:
		_ball_energy = _find_ball_energy()
	if _ball_energy == null:
		push_warning("QteOverlay: BallEnergy não encontrado.")
		return

	_answered = false
	_qte_manager.qte_duration = qte_duration
	_qte_manager.slow_motion_scale = slow_motion_scale
	_qte_manager.start_qte(barrier)

	var question_data := _question_generator.generate_random(_ball_energy)
	if question_data.is_empty():
		return

	_current_correct_index = question_data["correct_index"]
	_question_label.text = question_data["question"]

	var alternatives: Array = question_data["alternatives"]
	_button_a.text = alternatives[0]
	_button_b.text = alternatives[1]
	_button_c.text = alternatives[2]

	_update_attributes()
	_show_overlay()


func _on_button_pressed(index: int) -> void:
	if _answered:
		return
	_answered = true

	var correct := index == _current_correct_index
	var pressed_button := _get_button(index)

	if correct:
		_set_button_color(pressed_button, COLOR_CORRECT)
	else:
		_set_button_color(pressed_button, COLOR_WRONG)
		_set_button_color(_get_button(_current_correct_index), COLOR_CORRECT)

	_set_buttons_disabled(true)
	answer_selected.emit(correct)
	_qte_manager.answer(correct)


func _on_qte_finished(barrier: QteBarrier, correct: bool) -> void:
	if not _answered:
		_set_button_color(_get_button(_current_correct_index), COLOR_CORRECT)
		_set_buttons_disabled(true)

	if correct:
		_handle_correct(barrier)
	else:
		_handle_wrong(barrier)


func _handle_correct(barrier: QteBarrier) -> void:
	_play_sound(correct_sound)
	if _reward_sprite != null:
		_reward_sprite.visible = true
		_reward_sprite.play()
	barrier.remove_barrier()
	get_tree().create_timer(result_display_time, false, false, true).timeout.connect(_hide_overlay)


func _handle_wrong(_barrier: QteBarrier) -> void:
	_play_sound(wrong_sound)
	get_tree().create_timer(result_display_time, false, false, true).timeout.connect(_hide_overlay)


func _play_sound(stream: AudioStream) -> void:
	if stream == null or _audio_player == null:
		return
	_audio_player.stream = stream
	_audio_player.play()


func _on_time_updated(time_remaining: float) -> void:
	_timer_label.text = "%d" % ceili(time_remaining)


func _update_attributes() -> void:
	if _ball_energy == null:
		return
	_mass_label.text = "%.2f kg" % _ball_energy.mass
	_speed_label.text = "%.2f m/s" % _ball_energy.speed
	_ec_label.text = "%.2f J" % _ball_energy.kinetic_energy
	_ep_label.text = "%.2f J" % _ball_energy.potential_energy
	_et_label.text = "%.2f J" % _ball_energy.total_energy


func _show_overlay() -> void:
	_reset_button_colors()
	_set_buttons_disabled(false)
	visible = true
	_animate_in()


func _hide_overlay() -> void:
	visible = false
	if _reward_sprite != null:
		_reward_sprite.visible = false
		_reward_sprite.stop()


func _animate_in() -> void:
	_vignette.modulate.a = 0.0
	_question_label.position.y = -anim_slide_offset
	_buttons_container.position.y = anim_slide_offset

	var tween := create_tween().set_parallel(true)
	tween.tween_property(_vignette, "modulate:a", vignette_intensity, anim_duration)
	tween.tween_property(_question_label, "position:y", 0.0, anim_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_buttons_container, "position:y", 0.0, anim_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _get_button(index: int) -> Button:
	match index:
		0: return _button_a
		1: return _button_b
		2: return _button_c
		_: return _button_a


func _set_button_color(button: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(STYLE_CORNER_RADIUS)
	style.set_content_margin_all(STYLE_CONTENT_MARGIN)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)


func _reset_button_colors() -> void:
	for button: Button in [_button_a, _button_b, _button_c]:
		button.remove_theme_stylebox_override("normal")
		button.remove_theme_stylebox_override("hover")
		button.remove_theme_stylebox_override("pressed")
		button.remove_theme_stylebox_override("disabled")


func _set_buttons_disabled(disabled: bool) -> void:
	_button_a.disabled = disabled
	_button_b.disabled = disabled
	_button_c.disabled = disabled
