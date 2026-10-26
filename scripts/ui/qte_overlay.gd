class_name QteOverlay
extends CanvasLayer

const GROUP := &"qte_overlay"
const COLOR_CORRECT := Color("#22c55e")
const COLOR_WRONG := Color("#ef4444")
const STYLE_CORNER_RADIUS := 4
const STYLE_CONTENT_MARGIN := 8
const MIN_TIME_SCALE := 0.0001
const STYLE_STATES: Array[StringName] = [&"normal", &"hover", &"pressed", &"disabled"]

@export var player: Player

@export_category("QTE")
@export var qte_duration: float = 30.0
@export_range(0.0001, 1.0, 0.0001) var slow_motion_scale: float = 0.001

@export_category("Reactions")
@export var correct_reactions: Array[QteReaction] = []
@export var wrong_reactions: Array[QteReaction] = []

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
var _exit_tween: Tween
var _question_base_y: float
var _buttons_base_y: float
var _positions_initialized := false
var _buttons: Array[Button] = []
var _style_correct: StyleBoxFlat
var _style_wrong: StyleBoxFlat

@onready var _vignette: ColorRect = %Vignette
@onready var _question_label: Label = %QuestionLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _buttons_container: HBoxContainer = %ButtonsContainer
@onready var _button_a: Button = %ButtonA
@onready var _button_b: Button = %ButtonB
@onready var _button_c: Button = %ButtonC
@onready var _reward_sprite: AnimatedSprite2D = get_node_or_null("%RewardSprite")
@onready var _attributes_panel: Control = $AttributesPanel
@onready var _mass_label: Label = %QteMassValue
@onready var _speed_label: Label = %QteSpeedValue
@onready var _ec_label: Label = %QteEcValue
@onready var _ep_label: Label = %QteEpValue
@onready var _et_label: Label = %QteEtValue


func _ready() -> void:
	add_to_group(GROUP)

	add_child(_qte_manager)
	_qte_manager.time_updated.connect(_on_time_updated)

	_buttons = [_button_a, _button_b, _button_c]
	for i in _buttons.size():
		_buttons[i].pressed.connect(_on_button_pressed.bind(i))

	_style_correct = _create_feedback_style(COLOR_CORRECT)
	_style_wrong = _create_feedback_style(COLOR_WRONG)

	Events.qte_started.connect(_on_qte_started)
	Events.qte_finished.connect(_on_qte_finished)

	if player != null:
		_ball_energy = player.get_ball_energy()

	_hide_overlay()


func cancel_qte() -> void:
	_qte_manager.cancel()
	_hide_overlay()


func _on_qte_started(barrier: QteBarrier) -> void:
	if _ball_energy == null and player != null:
		_ball_energy = player.get_ball_energy()
	assert(_ball_energy != null, "QteOverlay: BallEnergy is required for QTE.")
	if _ball_energy == null:
		return

	var question_data := _question_generator.generate(_ball_energy, barrier.content)
	if question_data.is_empty():
		push_warning("QteOverlay: failed to generate question data.")
		return

	_answered = false
	_qte_manager.qte_duration = qte_duration
	_qte_manager.slow_motion_scale = slow_motion_scale
	_qte_manager.start_qte(barrier)

	_current_correct_index = question_data["correct_index"]
	_question_label.text = question_data["question"]

	var alternatives: Array = question_data["alternatives"]
	for i in _buttons.size():
		_buttons[i].text = alternatives[i]

	_attributes_panel.visible = question_data.get("show_attributes", false)
	_update_attributes()
	_show_overlay()


func _on_button_pressed(index: int) -> void:
	if _answered:
		return
	_answered = true

	var correct := index == _current_correct_index
	_set_button_style(_buttons[index], _style_correct if correct else _style_wrong)
	if not correct:
		_reveal_correct()
	_set_buttons_disabled(true)
	_qte_manager.answer(correct)


func _on_qte_finished(_barrier: QteBarrier, correct: bool) -> void:
	if not _answered:
		_reveal_correct()
		_set_buttons_disabled(true)

	if correct:
		_handle_correct()
	else:
		_handle_wrong()


func _handle_correct() -> void:
	_play_reaction(correct_reactions)
	_animate_out()


func _handle_wrong() -> void:
	_play_reaction(wrong_reactions)
	_animate_out()


func _reveal_correct() -> void:
	_set_button_style(_buttons[_current_correct_index], _style_correct)


func _animate_out() -> void:
	_kill_exit_tween()
	var exit_duration := anim_duration * 2.0
	var q_exit := _question_label.global_position.y + _question_label.size.y
	var viewport_h := get_viewport().get_visible_rect().size.y
	var b_exit := viewport_h - _buttons_container.global_position.y
	var speed := _get_tween_speed()
	_exit_tween = create_tween().set_parallel(true)
	_exit_tween.set_speed_scale(speed)
	_exit_tween.tween_property(_question_label, "position:y",
		_question_label.position.y - q_exit, exit_duration)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	_exit_tween.tween_property(_buttons_container, "position:y",
		_buttons_container.position.y + b_exit, exit_duration)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	_exit_tween.tween_property(_vignette, "modulate:a", 0.0, exit_duration)
	_exit_tween.finished.connect(_hide_overlay)


func _play_reaction(reactions: Array[QteReaction]) -> void:
	if reactions.is_empty():
		return

	var reaction: QteReaction = reactions.pick_random()

	if reaction.sound != null:
		SFXPool.play(reaction.sound)

	if reaction.sprite_frames != null and _reward_sprite != null:
		_reward_sprite.sprite_frames = reaction.sprite_frames
		_reward_sprite.animation = reaction.animation_name
		_reward_sprite.visible = true
		_reward_sprite.play()


func _on_time_updated(time_remaining: float) -> void:
	_timer_label.text = "%d" % ceili(time_remaining)


func _update_attributes() -> void:
	if _ball_energy == null:
		return
	_mass_label.text = AttributeFormat.format_value(_ball_energy.mass, "kg")
	_speed_label.text = AttributeFormat.format_speed(_ball_energy.speed)
	_ec_label.text = AttributeFormat.format_value(_ball_energy.kinetic_energy, "J")
	_ep_label.text = AttributeFormat.format_value(_ball_energy.potential_energy, "J")
	_et_label.text = AttributeFormat.format_value(_ball_energy.total_energy, "J")


func _show_overlay() -> void:
	_reset_button_colors()
	_set_buttons_disabled(false)
	visible = true
	if not _positions_initialized:
		_question_base_y = _question_label.position.y
		_buttons_base_y = _buttons_container.position.y
		_positions_initialized = true
	else:
		_question_label.position.y = _question_base_y
		_buttons_container.position.y = _buttons_base_y
	_animate_in()
	_start_countdown()


func _hide_overlay() -> void:
	_kill_exit_tween()
	visible = false
	if _reward_sprite != null:
		_reward_sprite.visible = false
		_reward_sprite.stop()


func _animate_in() -> void:
	_question_label.position.y = _question_base_y
	_buttons_container.position.y = _buttons_base_y
	_vignette.modulate.a = 0.0

	var speed := _get_tween_speed()
	var tween := create_tween().set_parallel(true)
	tween.set_speed_scale(speed)
	tween.tween_property(_vignette, "modulate:a", vignette_intensity, anim_duration)
	tween.tween_property(_question_label, "position:y", _question_base_y, anim_duration)\
		.from(_question_base_y - anim_slide_offset)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_buttons_container, "position:y", _buttons_base_y, anim_duration)\
		.from(_buttons_base_y + anim_slide_offset)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _start_countdown() -> void:
	var speed := _get_tween_speed()
	var viewport_h := get_viewport().get_visible_rect().size.y
	var q_slide := _question_label.global_position.y
	var b_slide := viewport_h - _buttons_container.global_position.y - _buttons_container.size.y

	_kill_exit_tween()
	_exit_tween = create_tween().set_parallel(true)
	_exit_tween.set_speed_scale(speed)
	_exit_tween.tween_property(_question_label, "position:y",
		_question_base_y - q_slide, qte_duration)\
		.set_delay(anim_duration)
	_exit_tween.tween_property(_buttons_container, "position:y",
		_buttons_base_y + b_slide, qte_duration)\
		.set_delay(anim_duration)


func _get_tween_speed() -> float:
	return 1.0 / maxf(Engine.time_scale, MIN_TIME_SCALE)


func _kill_exit_tween() -> void:
	if _exit_tween != null and _exit_tween.is_valid():
		_exit_tween.kill()


func _create_feedback_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(STYLE_CORNER_RADIUS)
	style.set_content_margin_all(STYLE_CONTENT_MARGIN)
	return style


func _set_button_style(button: Button, style: StyleBoxFlat) -> void:
	for state in STYLE_STATES:
		button.add_theme_stylebox_override(state, style)


func _reset_button_colors() -> void:
	for button in _buttons:
		for state in STYLE_STATES:
			button.remove_theme_stylebox_override(state)


func _set_buttons_disabled(disabled: bool) -> void:
	for button in _buttons:
		button.disabled = disabled
