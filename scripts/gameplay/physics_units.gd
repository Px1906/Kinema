class_name PhysicsUnits
extends RefCounted
## Escala entre pixels e unidades do SI. A bola padrão (raio 16 px) tem 1 m de diâmetro.
## Mantenha physics/2d/default_gravity igual a GRAVITY * PIXELS_PER_METER.

const PIXELS_PER_METER := 32.0
const GRAVITY := 10.0


static func gravity_pixels() -> float:
	return GRAVITY * PIXELS_PER_METER


static func pixels_to_meters(pixels: float) -> float:
	return pixels / PIXELS_PER_METER


static func meters_to_pixels(meters: float) -> float:
	return meters * PIXELS_PER_METER
