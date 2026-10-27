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
## Um clique do knob a cada tantos m/s da velocidade de saída (a mesma do painel).
@export_range(0.5, 20.0, 0.5, "suffix:m/s") var speed_notch_step: float = 1.0
## Um clique do knob a cada tantos graus de ângulo.
@export_range(1.0, 45.0, 1.0, "suffix:°") var angle_notch_step: float = 10.0

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
			_last_speed_notch = floori(_get_speed_notch_position())
			_last_angle_notch = floori(_get_angle_notch_position())
			get_viewport().set_input_as_handled()
		elif _dragging:
			_dragging = false
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _dragging:
		if not player.can_launch():
			_dragging = false
		else:
			_current = event.global_position
			_apply_launch_vector()
			get_viewport().set_input_as_handled()

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

	var sn := KnobNotch.next(
		_get_speed_notch_position(), _last_speed_notch, _is_speed_at_limit()
	)
	var an := KnobNotch.next(
		_get_angle_notch_position(), _last_angle_notch, _is_angle_at_limit()
	)
	if (sn != _last_speed_notch or an != _last_angle_notch) and _last_speed_notch >= 0:
		if knob_sound != null:
			SFXPool.play_random_pitch(knob_sound, 0.95, 1.05, knob_volume_db)
	_last_speed_notch = sn
	_last_angle_notch = an


## Posição da velocidade de saída em degraus. O +0,5 põe as bordas no meio dos
## inteiros: com passo de 1 m/s o clique sai quando o número do painel muda.
func _get_speed_notch_position() -> float:
	var speed_mps := PhysicsUnits.pixels_to_meters(player.get_initial_velocity().length())
	return speed_mps / speed_notch_step + 0.5


func _get_angle_notch_position() -> float:
	return player.launch_angle_degrees / angle_notch_step


func _is_speed_at_limit() -> bool:
	return player.launch_speed <= 0.0 or player.launch_speed >= minf(max_speed, Player.MAX_SPEED)


func _is_angle_at_limit() -> bool:
	var angle := player.launch_angle_degrees
	return angle <= player.get_min_launch_angle() or angle >= Player.MAX_ANGLE


func _on_player_state_changed(_new_state) -> void:
	_dragging = false

