extends PanelContainer
class_name LaunchControls

@export var player: Player
@export var rope: Rope:
	set(value):
		rope = value
		if is_node_ready():
			_connect_rope()

# Existing scene nodes are used when available; otherwise _build_ui() creates them.
@onready var _toggle_button: Button = get_node_or_null("%ToggleButton")
@onready var _sliders_box: Control = get_node_or_null("%SlidersBox")
@onready var _speed_label: Label = get_node_or_null("%SpeedLabel")
@onready var _speed_slider: Slider = get_node_or_null("%SpeedSlider")
@onready var _angle_label: Label = get_node_or_null("%AngleLabel")
@onready var _angle_slider: Slider = get_node_or_null("%AngleSlider")
@onready var _launch_button: Button = get_node_or_null("%LaunchButton")
@onready var _release_button: Button = get_node_or_null("%ReleaseButton")
var _rope_connected := false


func _ready() -> void:
	if player == null:
		push_warning("LaunchControls: assign the 'Player' property in the Inspector.")
		return

	if _toggle_button == null or _sliders_box == null \
			or _speed_slider == null or _angle_slider == null \
			or _speed_label == null or _angle_label == null or \
			_launch_button == null or _release_button == null:
		_build_ui()

	_toggle_button.toggled.connect(func(is_open: bool) -> void: _sliders_box.visible = is_open)
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


func _connect_rope() -> void:
	if rope == null or _rope_connected:
		return

	rope.player_attached.connect(_on_player_attached)
	rope.player_detached.connect(_on_player_detached)
	_release_button.disabled = not rope.is_player_attached()
	_rope_connected = true


# Fixed sizes keep the slider panel from changing dimensions while dragging.
const COLUMN_WIDTH := 130.0
const SLIDER_HEIGHT := 150.0
const BOX_SIZE := Vector2(260, 200)


# Fallback for scenes without preconfigured UI nodes.
func _build_ui() -> void:
	var root := VBoxContainer.new()
	add_child(root)

	# Always-visible row: [Adjust] [Launch]
	var row := HBoxContainer.new()
	root.add_child(row)

	_toggle_button = Button.new()
	_toggle_button.text = "Ajustar"
	_toggle_button.toggle_mode = true
	row.add_child(_toggle_button)

	_launch_button = Button.new()
	_launch_button.text = "Lançar"
	row.add_child(_launch_button)

	_release_button = Button.new()
	_release_button.text = "Soltar"
	_release_button.disabled = true
	row.add_child(_release_button)

	# Vertical sliders are toggled by the Adjust button.
	_sliders_box = HBoxContainer.new()
	_sliders_box.custom_minimum_size = BOX_SIZE
	root.add_child(_sliders_box)

	_speed_label = _make_column(_sliders_box)
	_speed_slider = _make_vertical_slider(0.0, 1000.0, 1.0, _speed_label.get_parent())

	_angle_label = _make_column(_sliders_box)
	_angle_slider = _make_vertical_slider(0.0, 180.0, 1.0, _angle_label.get_parent())


# Creates a fixed-width column with a centered label.
func _make_column(parent: Control) -> Label:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = COLUMN_WIDTH
	parent.add_child(column)

	var label := Label.new()
	label.custom_minimum_size.x = COLUMN_WIDTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	column.add_child(label)
	return label


func _make_vertical_slider(min_value: float, max_value: float, step: float, parent: Control) -> VSlider:
	var slider := VSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.custom_minimum_size = Vector2(0, SLIDER_HEIGHT)
	slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(slider)
	return slider


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
