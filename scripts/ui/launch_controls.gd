class_name LaunchControls
extends VBoxContainer

@export var player: Player
@export var launch_controller: LaunchInputController

@export_category("Slider SFX")
@export var knob_sound: AudioStream
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var knob_volume_db: float = 0.0
## Um clique do knob a cada tantos m/s da velocidade de saída (a mesma do painel).
@export_range(0.5, 20.0, 0.5, "suffix:m/s") var speed_notch_step: float = 1.0
## Um clique do knob a cada tantos graus de ângulo.
@export_range(1.0, 45.0, 1.0, "suffix:°") var angle_notch_step: float = 10.0

var _last_speed_notch := -1
var _last_angle_notch := -1
var _applying_slider := false

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
	_last_speed_notch = floori(_get_speed_notch_position())
	_last_angle_notch = floori(_get_angle_notch_position())


func _on_toggle_button_toggled(is_open: bool) -> void:
	_sliders_box.visible = is_open


# Slider -> Player
func _on_slider_changed(_value: float) -> void:
	_applying_slider = true
	player.set_launch_parameters(_speed_slider.value, _angle_slider.value)
	_applying_slider = false

	var speed_notch := KnobNotch.next(
		_get_speed_notch_position(), _last_speed_notch, _is_speed_at_limit()
	)
	var angle_notch := KnobNotch.next(
		_get_angle_notch_position(), _last_angle_notch, _is_angle_at_limit()
	)
	# O degrau da velocidade nunca é negativo: -1 só antes de inicializar. O do ângulo
	# pode ser (ângulo negativo), então não serve de sentinela.
	var changed := _last_speed_notch >= 0 \
		and (speed_notch != _last_speed_notch or angle_notch != _last_angle_notch)

	_last_speed_notch = speed_notch
	_last_angle_notch = angle_notch

	if changed:
		_play_knob_click()


## Posição da velocidade de saída em degraus. O +0,5 põe as bordas no meio dos
## inteiros: com passo de 1 m/s o clique sai quando o número do painel muda.
func _get_speed_notch_position() -> float:
	var speed_mps := PhysicsUnits.pixels_to_meters(player.get_initial_velocity().length())
	return speed_mps / speed_notch_step + 0.5


func _get_angle_notch_position() -> float:
	return player.launch_angle_degrees / angle_notch_step


func _is_speed_at_limit() -> bool:
	return player.launch_speed <= 0.0 or player.launch_speed >= Player.MAX_SPEED


func _is_angle_at_limit() -> bool:
	var angle := player.launch_angle_degrees
	return angle <= player.get_min_launch_angle() or angle >= Player.MAX_ANGLE


# Player -> Slider (without emitting value_changed and creating a loop)
func _on_player_params_changed(speed: float, angle: float) -> void:
	_speed_slider.set_value_no_signal(speed)
	_angle_slider.set_value_no_signal(angle)
	# Mostra a velocidade com que a bola sai de fato (já com o fator de lançamento), em m/s.
	var initial_speed := PhysicsUnits.pixels_to_meters(player.get_initial_velocity().length())
	# Nome e valor em linhas separadas: cabem na largura da coluna sem cortar.
	_speed_label.text = "Velocidade\n%s" % AttributeFormat.format_speed(initial_speed)
	_angle_label.text = "Ângulo\n%d°" % angle
	# Mudou por fora (arraste do mouse): os degraus acompanham, senão o próximo toque
	# no slider clicaria na hora por causa do valor antigo.
	if not _applying_slider:
		_last_speed_notch = floori(_get_speed_notch_position())
		_last_angle_notch = floori(_get_angle_notch_position())


func _play_knob_click() -> void:
	if knob_sound == null:
		return
	SFXPool.play_random_pitch(knob_sound, 0.95, 1.05, knob_volume_db)


## Soltar vale para qualquer corda da fase: basta a bola estar presa (ATTACHED).
func _on_player_state_changed(state: Player.State) -> void:
	_launch_button.disabled = state != Player.State.READY
	_release_button.disabled = state != Player.State.ATTACHED
