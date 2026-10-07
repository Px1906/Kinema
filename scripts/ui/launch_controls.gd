extends CanvasLayer
class_name LaunchControls

@export var player: Player

var _speed_slider: HSlider
var _angle_slider: HSlider
var _speed_label: Label
var _angle_label: Label
var _launch_button: Button


func _ready() -> void:
	_build_ui()
	_on_player_params_changed(player.launch_speed, player.launch_angle_degrees)
	player.set_launch_parameters(player.launch_speed, player.launch_angle_degrees)
	player.launch_parameters_changed.connect(_on_player_params_changed)
	player.launched.connect(func(_v: Vector2) -> void: _launch_button.disabled = true)


func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(20, 20)
	box.custom_minimum_size = Vector2(260, 0)
	add_child(box)

	_speed_label = Label.new()
	box.add_child(_speed_label)
	_speed_slider = _make_slider(0.0, 1000.0, 1.0, box)

	_angle_label = Label.new()
	box.add_child(_angle_label)
	_angle_slider = _make_slider(0.0, 180.0, 1.0, box)

	_launch_button = Button.new()
	_launch_button.text = "Lançar"
	_launch_button.pressed.connect(player.launch)
	box.add_child(_launch_button)


func _make_slider(min_v: float, max_v: float, step: float, parent: Control) -> HSlider:
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value_changed.connect(_on_slider_changed)
	parent.add_child(s)
	return s


# Slider -> Player
func _on_slider_changed(_v: float) -> void:
	player.set_launch_parameters(_speed_slider.value, _angle_slider.value)


# Player -> Slider	
func _on_player_params_changed(speed: float, angle: float) -> void:
	_speed_slider.set_value_no_signal(speed)
	_angle_slider.set_value_no_signal(angle)
	_speed_label.text = "Velocidade: %d" % speed
	_angle_label.text = "Ângulo: %d°" % angle
