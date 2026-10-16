class_name BallAttributes
extends VBoxContainer
## Pop-up com os atributos da bola. Massa e velocidade são numéricas; as energias
## cinética e potencial são barras de 0 até a energia total.

const MIN_BAR_MAX := 0.001

@export var player: Player

var _ball_energy: BallEnergy

@onready var _toggle_button: Button = %ToggleButton
@onready var _content_box: Control = %ContentBox
@onready var _mass_value: Label = %MassValue
@onready var _speed_value: Label = %SpeedValue
@onready var _total_value: Label = %TotalValue
@onready var _kinetic_bar: ProgressBar = %KineticBar
@onready var _kinetic_value: Label = %KineticValue
@onready var _potential_bar: ProgressBar = %PotentialBar
@onready var _potential_value: Label = %PotentialValue


func _ready() -> void:
	_toggle_button.toggled.connect(_on_toggle_button_toggled)
	_content_box.visible = _toggle_button.button_pressed

	if player == null:
		push_warning("BallAttributes: assign the 'Player' property in the Inspector.")
		return

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


func _on_toggle_button_toggled(is_open: bool) -> void:
	_content_box.visible = is_open
	if is_open and _ball_energy != null:
		_on_energy_updated(_ball_energy)


func _on_energy_updated(ball_energy: BallEnergy) -> void:
	if not _content_box.visible:
		return

	_mass_value.text = "%.2f kg" % ball_energy.mass
	_speed_value.text = "%.2f m/s" % ball_energy.speed
	_total_value.text = "%.2f J" % ball_energy.total_energy

	# Abaixo da referência Ep fica negativa; as barras mostram o valor limitado a 0..E.
	var bar_max := maxf(ball_energy.total_energy, MIN_BAR_MAX)
	_set_bar(_kinetic_bar, _kinetic_value, ball_energy.kinetic_energy, bar_max)
	_set_bar(_potential_bar, _potential_value, ball_energy.potential_energy, bar_max)


func _set_bar(bar: ProgressBar, value_label: Label, value: float, bar_max: float) -> void:
	bar.max_value = bar_max
	bar.value = clampf(value, 0.0, bar_max)
	value_label.text = "%.2f J" % value
