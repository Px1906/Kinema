class_name BallEnergy
extends Node
## Calcula as grandezas da bola em unidades do SI a cada passo de física.
## Deve ser filho do Player. A altura é medida a partir do HeightReference da fase.

signal energy_updated(ball_energy: BallEnergy)

## Alturas menores que isto (em px) contam como zero: parada sobre uma superfície, a
## bola afunda um pouco no contato (contact_max_allowed_penetration) e ficaria com
## energia potencial levemente negativa no nível da referência.
const HEIGHT_TOLERANCE_PIXELS := 1.0
## Rodadas de recuperação da penetração. Cada body_test_motion desfaz ~87% dela
## (quatro iterações internas de 40%); duas rodadas deixam menos de 2%.
const DEPENETRATION_PASSES := 2

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
	speed = (
		0.0 if _is_at_rest() else PhysicsUnits.pixels_to_meters(_get_measured_velocity().length())
	)
	height = _get_height()
	kinetic_energy = 0.5 * mass * speed * speed
	potential_energy = mass * PhysicsUnits.GRAVITY * height
	total_energy = kinetic_energy + potential_energy
	energy_updated.emit(self)


## Parada (pronta para lançar ou após parar) ignora a velocidade residual da física.
func _is_at_rest() -> bool:
	var state := player.get_state()
	return state == Player.State.READY or state == Player.State.STOPPED


## A física do Godot (Euler semi-implícito) soma a gravidade à velocidade antes de
## mover a bola. A posição atual fica, então, entre a velocidade de chegada e a de
## saída do passo: usar linear_velocity crua faz Ec + Ep cair ½·m·g²·Δt² a cada passo
## em pleno voo. A velocidade no meio do passo (v + ½·g·Δt) conserva a energia.
## Rolando no chão, a correção soma só ~0,08 m/s para baixo, desprezível.
func _get_measured_velocity() -> Vector2:
	var velocity := player.get_current_velocity()
	if player.get_state() != Player.State.MOVING:
		return velocity
	var gravity := player.get_gravity() * player.gravity_scale
	return velocity + gravity * get_physics_process_delta_time() * 0.5


## No passo do impacto a bola fica afundada alguns px no chão até o solver empurrá-la
## para fora. A altura usa a posição já sem essa penetração, como se o solver tivesse
## terminado; sem isso, a Ep pisca negativa a cada quique no nível da referência.
func _get_resolved_base_position() -> Vector2:
	var base := player.get_base_global_position()
	if player.get_state() != Player.State.MOVING:
		return base

	var params := PhysicsTestMotionParameters2D.new()
	params.from = player.global_transform
	params.margin = 0.0
	var result := PhysicsTestMotionResult2D.new()
	for _pass in DEPENETRATION_PASSES:
		if not PhysicsServer2D.body_test_motion(player.get_rid(), params, result):
			break
		params.from.origin += result.get_travel()
	return base + params.from.origin - player.global_position


func _get_height() -> float:
	var base := _get_resolved_base_position()
	var height_meters := (
		PhysicsUnits.pixels_to_meters(-base.y)
		if _height_reference == null
		else _height_reference.get_height_meters(base)
	)
	if absf(height_meters) < PhysicsUnits.pixels_to_meters(HEIGHT_TOLERANCE_PIXELS):
		return 0.0
	return height_meters
