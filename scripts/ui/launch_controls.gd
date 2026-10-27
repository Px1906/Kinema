class_name LaunchControls
extends VBoxContainer

@export var player: Player
@export var launch_controller: LaunchInputController

@export_category("Slider SFX")
@export var knob_sound: AudioStream
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var knob_volume_db: float = 0.0
@export_range(1.0, 100.0, 1.0) var speed_notch_step: float = 50.0
@export_range(1.0, 45.0, 1.0) var angle_notch_step: float = 10.0

var _last_speed_notch := -1
var _last_angle_notch := -1

@onready var _toggle_button: Button = %ToggleButton
@onready var _sliders_box: Control = %SlidersBox
@onready var _speed_label: Label = %SpeedLabel
@onready var _speed_slider: Slider = %SpeedSlider
@onready var _angle_label: Label = %AngleLabel
@onready var _angle_slider: Slider = %AngleSlider
@onready var _launch_button: Button = %LaunchButton
@onready var _release_button: Button = %ReleaseButton


func _ready() -> void:
	# Reserva a largura do painel antes de escondê-lo: senão o popup nasce com a largura
	# só da linha de botões e eles "pulam" para o centro na primeira vez que abre.
	custom_minimum_size.x = maxf(custom_minimum_size.x, get_combined_minimum_size().x)

	if player == null:
		push_warning("LaunchControls: assign the 'Player' property in the Inspector.")
		return
	if launch_controller == null:
		push_warning("LaunchControls: assign the 'LaunchInputController' property in the Inspector.")
		return

	# Slider ranges (values come from the Player constants).
	_speed_slider.min_value = 0.0
	_speed_slider.max_value = Player.MAX_SPEED
	_angle_slider.min_value = player.get_min_launch_angle()
	_angle_slider.max_value = Player.MAX_ANGLE

	_toggle_button.toggled.connect(_on_toggle_button_toggled)
	_sliders_box.visible = _toggle_button.button_pressed

	_speed_slider.value_changed.connect(_on_slider_changed)
	_angle_slider.value_changed.connect(_on_slider_changed)
	_launch_button.pressed.connect(launch_controller.launch)
	_release_button.pressed.connect(launch_controller.release)
	player.launch_parameters_changed.connect(_on_player_params_changed)
	player.state_changed.connect(_on_player_state_changed)
	_on_player_state_changed(player.get_state())
	# The Launch button remains visible and is disabled after launching.
	player.launched.connect(func(_v: Vector2) -> void: _launch_button.disabled = true)

	_on_player_params_changed(player.launch_speed, player.launch_angle_degrees)
	player.set_launch_parameters(player.launch_speed, player.launch_angle_degrees)
	_last_speed_notch = int(player.launch_speed / speed_notch_step)
	_last_angle_notch = int(player.launch_angle_degrees / angle_notch_step)


func _on_toggle_button_toggled(is_open: bool) -> void:
	_sliders_box.visible = is_open


# Slider -> Player
func _on_slider_changed(_value: float) -> void:
	player.set_launch_parameters(_speed_slider.value, _angle_slider.value)

	var speed_notch := int(_speed_slider.value / speed_notch_step)
	var angle_notch := int(_angle_slider.value / angle_notch_step)
	var changed := false

	if speed_notch != _last_speed_notch and _last_speed_notch >= 0:
		changed = true
	if angle_notch != _last_angle_notch and _last_angle_notch >= 0:
		changed = true

	_last_speed_notch = speed_notch
	_last_angle_notch = angle_notch

	if changed:
		_play_knob_click()


# Player -> Slider (without emitting value_changed and creating a loop)
func _on_player_params_changed(speed: float, angle: float) -> void:
	_speed_slider.set_value_no_signal(speed)
	_angle_slider.set_value_no_signal(angle)
	_speed_label.text = "Velocidade: %d" % speed
	_angle_label.text = "Ângulo: %d°" % angle


func _play_knob_click() -> void:
	if knob_sound == null:
		return
	SFXPool.play_random_pitch(knob_sound, 0.95, 1.05, knob_volume_db)


## Soltar vale para qualquer corda da fase: basta a bola estar presa (ATTACHED).
func _on_player_state_changed(state: Player.State) -> void:
	_launch_button.disabled = state != Player.State.READY
	_release_button.disabled = state != Player.State.ATTACHED
