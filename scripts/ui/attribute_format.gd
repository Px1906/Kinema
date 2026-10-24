class_name AttributeFormat
extends RefCounted
## Formato dos atributos da bola na UI: números inteiros, e a velocidade abaixo de
## 1 m/s com uma casa decimal.


## Parte inteira, subindo só quando a fração passa de 0,5 (2,5 → 2; 2,6 → 3).
## Negativos seguem a mesma regra pelo valor absoluto (-2,6 → -3).
static func round_value(value: float) -> int:
	var magnitude := absf(value)
	var whole := floorf(magnitude)
	if magnitude - whole > 0.5:
		whole += 1.0
	return int(signf(value) * whole)


static func format_value(value: float, unit: String) -> String:
	return "%d %s" % [round_value(value), unit]


## Abaixo de 0,95 m/s mostra uma casa decimal; daí para cima "%.1f" já daria
## "1.0", então passa a ser inteiro.
static func format_speed(speed: float) -> String:
	if absf(speed) < 0.95:
		return "%.1f m/s" % speed
	return format_value(speed, "m/s")
