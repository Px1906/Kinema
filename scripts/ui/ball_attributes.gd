class_name BallAttributes
extends VBoxContainer
## Pop-up com os atributos da bola. Massa e velocidade são numéricas; as energias
## cinética e potencial são barras de 0 até a energia total.

const MIN_BAR_MAX := 0.001
const NEGATIVE_COLOR := Color("#f87171")

@export var player: Player

var _ball_energy: BallEnergy

@onready var _toggle_button: Button = %ToggleButton
@onready var _reference_button: Button = %ReferenceButton
@onready var _content_box: Control = %ContentBox
@onready var _mass_value: Label = %MassValue
@onready var _speed_value: Label = %SpeedValue
@onready var _total_value: Label = %TotalValue
@onready var _kinetic_bar: ProgressBar = %KineticBar
@onready var _kinetic_value: Label = %KineticValue
@onready var _potential_bar: ProgressBar = %PotentialBar
@onready var _potential_value: Label = %PotentialValue
@onready var _potential_warning: Label = %PotentialWarning


func _ready() -> void:
	# Reserva a largura do painel antes de escondê-lo: senão o popup nasce com a largura
	# só da linha de botões e eles "pulam" para o centro na primeira vez que abre.
	custom_minimum_size.x = maxf(custom_minimum_size.x, get_combined_minimum_size().x)

	_toggle_button.toggled.connect(_on_toggle_button_toggled)
	_content_box.visible = _toggle_button.button_pressed

	if player == null:
		push_warning("BallAttributes: assign the 'Player' property in the Inspector.")
		_reference_button.disabled = true
		return

	# A referência só muda com a bola pronta para lançar, nunca no meio de uma tentativa.
	_reference_button.pressed.connect(_on_reference_button_pressed)
	player.state_changed.connect(_on_player_state_changed)
	_on_player_state_changed(player.get_state())

	_ball_energy = _find_ball_energy()
	if _ball_energy == null:
		push_warning("BallAttributes: o Player não tem um nó BallEnergy.")
		return

	_ball_energy.energy_updated.connect(_on_energy_updated)
	_on_energy_updated(_ball_energy)


func _find_ball_energy() -> BallEnergy:
	for child in player.get_children():
		if child is BallEnergy:
			return child

	return null


func _on_player_state_changed(state: Player.State) -> void:
	_reference_button.disabled = state != Player.State.READY


func _on_reference_button_pressed() -> void:
	if not player.can_launch():
		return
	var reference := get_tree().get_first_node_in_group(HeightReference.GROUP) as HeightReference
	if reference == null:
		push_warning("BallAttributes: nenhum HeightReference na fase para mover.")
		return
	reference.move_to(player.get_base_global_position())


func _on_toggle_button_toggled(is_open: bool) -> void:
	_content_box.visible = is_open
	if is_open and _ball_energy != null:
		_on_energy_updated(_ball_energy)


func _on_energy_updated(ball_energy: BallEnergy) -> void:
	if not _content_box.visible:
		return

	_mass_value.text = AttributeFormat.format_value(ball_energy.mass, "kg")
	_speed_value.text = AttributeFormat.format_speed(ball_energy.speed)
	_total_value.text = AttributeFormat.format_value(ball_energy.total_energy, "J")

	# Abaixo da referência Ep fica negativa; as barras mostram o valor limitado a 0..E.
	var bar_max := maxf(ball_energy.total_energy, MIN_BAR_MAX)
	_set_bar(_kinetic_bar, _kinetic_value, ball_energy.kinetic_energy, bar_max)
	_set_bar(_potential_bar, _potential_value, ball_energy.potential_energy, bar_max)

	# Usa o mesmo arredondamento do rótulo, para não avisar quando ele mostra "0 J".
	var is_negative := AttributeFormat.round_value(ball_energy.potential_energy) < 0
	_potential_warning.visible = is_negative
	if is_negative:
		_potential_value.add_theme_color_override("font_color", NEGATIVE_COLOR)
	else:
		_potential_value.remove_theme_color_override("font_color")


func _set_bar(bar: ProgressBar, value_label: Label, value: float, bar_max: float) -> void:
	bar.max_value = bar_max
	bar.value = clampf(value, 0.0, bar_max)
	value_label.text = AttributeFormat.format_value(value, "J")
