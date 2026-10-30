class_name KnobNotch
extends RefCounted
## Degraus de um knob com histerese, para o clique não repetir quando o valor fica
## tremendo em cima da borda entre dois degraus (mão parada no mouse, por exemplo).

## Quanto do passo o valor precisa passar da borda para trocar de degrau.
const HYSTERESIS := 0.2


## position: valor já dividido pelo passo, com as bordas entre degraus nos inteiros.
## Devolve o degrau novo, ou last enquanto o valor não passa da borda com folga.
## at_limit: o valor está no mínimo ou no máximo e não tem como passar da borda com
## folga (180° parado em 180°), então troca de degrau sem histerese.
static func next(position: float, last: int, at_limit := false) -> int:
	var notch := floori(position)
	if at_limit:
		return notch
	if notch > last and position < last + 1 + HYSTERESIS:
		return last
	if notch < last and position > last - HYSTERESIS:
		return last
	return notch
