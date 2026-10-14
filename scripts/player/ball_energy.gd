class_name BallEnergy
extends Node
## Calcula as grandezas da bola em unidades do SI a cada passo de física.
## Deve ser filho do Player. A altura é medida a partir do HeightReference da fase.

signal energy_updated(ball_energy: BallEnergy)

## Massa em kg.
var mass: float = 0.0
## Área do disco em m².
var area: float = 0.0
## Módulo da velocidade em m/s.
var speed: float = 0.0
## Altura em m acima da referência.
var height: float = 0.0
## Energia cinética em J.
var kinetic_energy: float = 0.0
## Energia potencial gravitacional em J.
var potential_energy: float = 0.0
## Energia mecânica total em J.
var total_energy: float = 0.0

var _height_reference: HeightReference

@onready var player: Player = get_parent() as Player


func _ready() -> void:
	if player == null:
		push_warning("BallEnergy: o nó pai precisa ser um Player.")
		set_physics_process(false)
		return

	_height_reference = (
		get_tree().get_first_node_in_group(HeightReference.GROUP) as HeightReference
	)
	if _height_reference == null:
		push_warning("BallEnergy: nenhum HeightReference na fase; usando y = 0 como altura zero.")

	_update_values()


func _physics_process(_delta: float) -> void:
	_update_values()


func _update_values() -> void:
	var radius_meters := PhysicsUnits.pixels_to_meters(player.radius)
	mass = player.mass
	area = PI * radius_meters * radius_meters
	speed = PhysicsUnits.pixels_to_meters(player.get_current_velocity().length())
	height = _get_height()
	kinetic_energy = 0.5 * mass * speed * speed
	potential_energy = mass * PhysicsUnits.GRAVITY * height
	total_energy = kinetic_energy + potential_energy
	energy_updated.emit(self)


func _get_height() -> float:
	if _height_reference == null:
		return PhysicsUnits.pixels_to_meters(-player.global_position.y)

	return _height_reference.get_height_meters(player.global_position)
