extends PanelContainer
class_name LaunchControls

@export var player: Player

@onready var _toggle_button: Button = %ToggleButton
@onready var _sliders_box: Control = %SlidersBox
@onready var _speed_label: Label = %SpeedLabel
@onready var _speed_slider: Slider = %SpeedSlider
@onready var _angle_label: Label = %AngleLabel
@onready var _angle_slider: Slider = %AngleSlider
@onready var _launch_button: Button = %LaunchButton


func _ready() -> void:
	if player == null:
		push_warning("LaunchControls: preencha o campo 'Player' no Inspetor.")
		return

	# Faixas dos sliders (valores vêm das constantes do Player).
	_speed_slider.min_value = 0.0
	_speed_slider.max_value = Player.MAX_SPEED
	_angle_slider.min_value = -Player.MAX_ANGLE if player.inicio_suspenso else 0.0
	_angle_slider.max_value = Player.MAX_ANGLE

	_toggle_button.toggled.connect(_on_toggle_button_toggled)
	_sliders_box.visible = _toggle_button.button_pressed

	_speed_slider.value_changed.connect(_on_slider_changed)
	_angle_slider.value_changed.connect(_on_slider_changed)
	_launch_button.pressed.connect(player.launch)
	player.launch_parameters_changed.connect(_on_player_params_changed)

	_on_player_params_changed(player.launch_speed, player.launch_angle_degrees)
	player.set_launch_parameters(player.launch_speed, player.launch_angle_degrees)

func _on_toggle_button_toggled(is_open: bool) -> void:
	_sliders_box.visible = is_open


func _on_slider_changed(_v: float) -> void:
	player.set_launch_parameters(_speed_slider.value, _angle_slider.value)


# Player -> Slider (sem disparar value_changed, evitando loop)
func _on_player_params_changed(speed: float, angle: float) -> void:
	_speed_slider.set_value_no_signal(speed)
	_angle_slider.set_value_no_signal(angle)
	_speed_label.text = "Velocidade: %d" % speed
	_angle_label.text = "Ângulo: %d°" % angle
