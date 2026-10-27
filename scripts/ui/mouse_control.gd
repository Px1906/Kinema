class_name MouseControl
extends Control

@export var player: Player
@export var launch_controller: LaunchInputController

@export_category("Launch Vector")
@export var invert_direction: bool = false
@export var speed_factor: float = 3.0
@export var max_speed: float = Player.MAX_SPEED
@export var min_distance: float = 5.0

@export_category("Drag SFX")
@export var knob_sound: AudioStream
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var knob_volume_db: float = 0.0
@export_range(1.0, 100.0, 1.0) var speed_notch_step: float = 50.0
@export_range(1.0, 45.0, 1.0) var angle_notch_step: float = 10.0

@export_category("Visual")
@export var vector_color := Color("#f87171")

var _dragging := false
var _last_speed_notch := -1
var _last_angle_notch := -1
var _start := Vector2.ZERO
var _current := Vector2.ZERO


func _ready() -> void:
	if player == null:
		return
	if launch_controller == null:
		push_warning("MouseControl: assign the 'LaunchInputController' property in the Inspector.")

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	player.state_changed.connect(_on_player_state_changed)
	set_process_unhandled_input(true)
	set_process_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if player == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and player.can_launch() and not _is_over_height_reference():
			_dragging = true
			_start = player.get_global_transform_with_canvas().origin
			_current = event.global_position
			_last_speed_notch = int(player.launch_speed / speed_notch_step)
			_last_angle_notch = int(player.launch_angle_degrees / angle_notch_step)
			get_viewport().set_input_as_handled()
		elif _dragging:
			_dragging = false
			get_viewport().set_input_as_handled()
		queue_redraw()

	elif event is InputEventMouseMotion and _dragging:
		if not player.can_launch():
			_dragging = false
		else:
			_current = event.global_position
			_apply_launch_vector()
			get_viewport().set_input_as_handled()
		queue_redraw()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and _dragging:
			if launch_controller == null:
				return
			launch_controller.launch()
			get_viewport().set_input_as_handled()


func _is_over_height_reference() -> bool:
	var global_mouse := get_global_mouse_position()
	for ref: Node in get_tree().get_nodes_in_group(HeightReference.GROUP):
		var hr := ref as HeightReference
		if hr != null and hr.would_claim_input(global_mouse):
			return true
	return false


func _apply_launch_vector() -> void:
	var vector := _current - _start
	if invert_direction:
		vector = -vector
	if vector.length() < min_distance:
		return

	var angle := rad_to_deg(atan2(-vector.y, vector.x))
	angle = player.clamp_launch_angle(angle)
	var speed := minf(vector.length() * speed_factor, max_speed)
	player.set_launch_parameters(speed, angle)

	var sn := int(speed / speed_notch_step)
	var an := int(angle / angle_notch_step)
	if (sn != _last_speed_notch or an != _last_angle_notch) and _last_speed_notch >= 0:
		if knob_sound != null:
			SFXPool.play_random_pitch(knob_sound, 0.95, 1.05, knob_volume_db)
	_last_speed_notch = sn
	_last_angle_notch = an


func _on_player_state_changed(_new_state) -> void:
	_dragging = false
	queue_redraw()


func _draw() -> void:
	if not _dragging:
		return
	var offset := global_position
	var draw_start := _start - offset
	var draw_current := _current - offset
	draw_line(draw_start, draw_current, vector_color, 2.0)
	draw_circle(draw_start, 4.0, vector_color)
