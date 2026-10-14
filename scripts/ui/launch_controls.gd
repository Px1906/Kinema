class_name LaunchControls
extends VBoxContainer

@export var player: Player
@export var rope: Rope:
	set(value):
		rope = value
		if is_node_ready():
			_connect_rope()

var _rope_connected := false

@onready var _toggle_button: Button = %ToggleButton
@onready var _sliders_box: Control = %SlidersBox
@onready var _speed_label: Label = %SpeedLabel
@onready var _speed_slider: Slider = %SpeedSlider
@onready var _angle_label: Label = %AngleLabel
@onready var _angle_slider: Slider = %AngleSlider
@onready var _launch_button: Button = %LaunchButton
@onready var _release_button: Button = %ReleaseButton


func _ready() -> void:
	if player == null:
		push_warning("LaunchControls: assign the 'Player' property in the Inspector.")
		return

	# Slider ranges (values come from the Player constants).
	_speed_slider.min_value = 0.0
	_speed_slider.max_value = Player.MAX_SPEED
	_angle_slider.min_value = -Player.MAX_ANGLE if player.inicio_suspenso else 0.0
	_angle_slider.max_value = Player.MAX_ANGLE

	_toggle_button.toggled.connect(_on_toggle_button_toggled)
	_sliders_box.visible = _toggle_button.button_pressed

	_speed_slider.value_changed.connect(_on_slider_changed)
	_angle_slider.value_changed.connect(_on_slider_changed)
	_launch_button.pressed.connect(player.launch)
	_release_button.pressed.connect(_release_player)
	_release_button.disabled = true
	player.launch_parameters_changed.connect(_on_player_params_changed)
	_connect_rope()
	# The Launch button remains visible and is disabled after launching.
	player.launched.connect(func(_v: Vector2) -> void: _launch_button.disabled = true)

	_on_player_params_changed(player.launch_speed, player.launch_angle_degrees)
	player.set_launch_parameters(player.launch_speed, player.launch_angle_degrees)


func _on_toggle_button_toggled(is_open: bool) -> void:
	_sliders_box.visible = is_open


func _connect_rope() -> void:
	if rope == null or _rope_connected:
		return

	rope.player_attached.connect(_on_player_attached)
	rope.player_detached.connect(_on_player_detached)
	_release_button.disabled = not rope.is_player_attached()
	_rope_connected = true


# Slider -> Player
func _on_slider_changed(_value: float) -> void:
	player.set_launch_parameters(_speed_slider.value, _angle_slider.value)


# Player -> Slider (without emitting value_changed and creating a loop)
func _on_player_params_changed(speed: float, angle: float) -> void:
	_speed_slider.set_value_no_signal(speed)
	_angle_slider.set_value_no_signal(angle)
	_speed_label.text = "Velocidade: %d" % speed
	_angle_label.text = "Ângulo: %d°" % angle


func _release_player() -> void:
	if rope == null or not rope.is_player_attached():
		return

	rope.detach_player()


func _on_player_attached(_attached_player: Player) -> void:
	_release_button.disabled = false


func _on_player_detached(_detached_player: Player) -> void:
	_release_button.disabled = true
