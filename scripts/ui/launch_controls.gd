extends PanelContainer
class_name LaunchControls

@export var player: Player
@export var rope: Rope:
	set(value):
		rope = value
		if is_node_ready():
			_connect_rope()

# Se existirem na cena (com "Acessar como Nome Único"), são usados.
# Se não existirem, _build_ui() cria tudo por código.
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
		push_warning("LaunchControls: preencha o campo 'Player' no Inspetor.")
		return

	if _toggle_button == null or _sliders_box == null \
			or _speed_slider == null or _angle_slider == null \
			or _speed_label == null or _angle_label == null or \
			_launch_button == null or _release_button == null:
		_build_ui()

	_toggle_button.toggled.connect(func(aberto: bool) -> void: _sliders_box.visible = aberto)
	_sliders_box.visible = _toggle_button.button_pressed

	_speed_slider.value_changed.connect(_on_slider_changed)
	_angle_slider.value_changed.connect(_on_slider_changed)
	_launch_button.pressed.connect(player.launch)
	_release_button.pressed.connect(_release_player)
	_release_button.disabled = true
	player.launch_parameters_changed.connect(_on_player_params_changed)
	_connect_rope()
	# O botão Lançar continua visível; só fica desativado depois do lançamento.
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


# Tamanhos fixos para a aba de sliders não mudar de dimensão ao arrastar.
const COLUNA_LARGURA := 130.0
const SLIDER_ALTURA := 150.0
const CAIXA_TAMANHO := Vector2(260, 200)


# Fallback: monta a interface por código quando os nós não existem na cena.
func _build_ui() -> void:
	var root := VBoxContainer.new()
	add_child(root)

	# Linha sempre visível: [Ajustar] [Lançar]
	var linha := HBoxContainer.new()
	root.add_child(linha)

	_toggle_button = Button.new()
	_toggle_button.text = "Ajustar"
	_toggle_button.toggle_mode = true
	linha.add_child(_toggle_button)

	_launch_button = Button.new()
	_launch_button.text = "Lançar"
	linha.add_child(_launch_button)

	_release_button = Button.new()
	_release_button.text = "Soltar"
	_release_button.disabled = true
	linha.add_child(_release_button)

	# Sliders verticais: aparecem/somem com o botão Ajustar
	_sliders_box = HBoxContainer.new()
	_sliders_box.custom_minimum_size = CAIXA_TAMANHO
	root.add_child(_sliders_box)

	_speed_label = _make_coluna(_sliders_box)
	_speed_slider = _make_vslider(0.0, 1000.0, 1.0, _speed_label.get_parent())

	_angle_label = _make_coluna(_sliders_box)
	_angle_slider = _make_vslider(0.0, 180.0, 1.0, _angle_label.get_parent())


# Cria uma coluna de largura fixa com um label centralizado; devolve o label.
func _make_coluna(parent: Control) -> Label:
	var coluna := VBoxContainer.new()
	coluna.custom_minimum_size.x = COLUNA_LARGURA
	parent.add_child(coluna)

	var label := Label.new()
	label.custom_minimum_size.x = COLUNA_LARGURA
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	coluna.add_child(label)
	return label


func _make_vslider(min_v: float, max_v: float, step: float, parent: Control) -> VSlider:
	var s := VSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.custom_minimum_size = Vector2(0, SLIDER_ALTURA)
	s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(s)
	return s


# Slider -> Player
func _on_slider_changed(_v: float) -> void:
	player.set_launch_parameters(_speed_slider.value, _angle_slider.value)


# Player -> Slider (sem disparar value_changed, evitando loop)
func _on_player_params_changed(speed: float, angle: float) -> void:
	_speed_slider.set_value_no_signal(speed)
	_angle_slider.set_value_no_signal(angle)
	_speed_label.text = "Velocidade: %d" % speed
	_angle_label.text = "Ângulo: %d°" % angle


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_SPACE:
		if rope != null and rope.is_player_attached():
			_release_player()
		elif player.state == Player.State.PREPARANDO:
			player.launch()


func _release_player() -> void:
	if rope == null or not rope.is_player_attached():
		return

	rope.detach_player()


func _on_player_attached(_attached_player: Player) -> void:
	_release_button.disabled = false


func _on_player_detached(_detached_player: Player) -> void:
	_release_button.disabled = true
