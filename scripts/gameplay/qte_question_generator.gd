class_name QteQuestionGenerator
extends RefCounted

const QUESTIONS_PATH := "res://resources/qte_questions.json"
const ZERO_VALUE_OFFSET := 0.5

var _rng := RandomNumberGenerator.new()
var _templates: Array[Dictionary] = []


func _init() -> void:
	_rng.randomize()
	_load_templates()


## Sorteia uma pergunta do conteúdo pedido. Conteúdo vazio sorteia entre todas.
func generate(ball_energy: BallEnergy, content: String) -> Dictionary:
	if _templates.is_empty():
		push_error("QteQuestionGenerator: nenhum modelo de pergunta carregado.")
		return {}

	var pool: Array = _templates
	if not content.is_empty():
		pool = _templates.filter(func(t: Dictionary) -> bool: return t.get("content", "") == content)
		if pool.is_empty():
			push_warning("QteQuestionGenerator: nenhuma pergunta com conteúdo '%s'; usando todas." % content)
			pool = _templates

	var template: Dictionary = pool[_rng.randi_range(0, pool.size() - 1)]
	return _generate_from_template(template, ball_energy)


func _generate_from_template(template: Dictionary, ball_energy: BallEnergy) -> Dictionary:
	if template.has("alternatives"):
		return _generate_fixed(template)

	var values := _build_values(ball_energy)
	var correct_value := _get_value(values, template.get("answer", ""))
	var question_text := _format_question_text(template, values)
	var unit: String = template.get("unit", "")
	var min_factor: float = template.get("wrong_min_factor", 0.3)
	var max_factor: float = template.get("wrong_max_factor", 2.5)

	var correct_answer := _format_value(correct_value, unit)
	var wrong_1 := _generate_wrong_answer(correct_value, unit, min_factor, max_factor, [correct_answer])
	var wrong_2 := _generate_wrong_answer(correct_value, unit, min_factor, max_factor, [correct_answer, wrong_1])

	var alternatives: Array[String] = [correct_answer, wrong_1, wrong_2]
	alternatives.shuffle()
	var correct_index := alternatives.find(correct_answer)

	return {
		"question": question_text,
		"alternatives": alternatives,
		"correct_index": correct_index,
		"show_attributes": template.get("show_attributes", false),
	}


## Pergunta com alternativas escritas no JSON (teoria ou cálculo com números fixos).
## A primeira alternativa é a certa; a ordem é embaralhada aqui.
func _generate_fixed(template: Dictionary) -> Dictionary:
	var source: Array = template.get("alternatives", [])
	if source.size() != 3:
		var text: String = template.get("text", "")
		push_error("QteQuestionGenerator: pergunta fixa precisa de 3 alternativas: %s" % text)
		return {}

	var correct_answer := str(source[0])
	var alternatives: Array[String] = []
	for alternative: Variant in source:
		alternatives.append(str(alternative))
	alternatives.shuffle()

	return {
		"question": template.get("text", ""),
		"alternatives": alternatives,
		"correct_index": alternatives.find(correct_answer),
		"show_attributes": template.get("show_attributes", false),
	}


## Valores inteiros que o JSON pode citar em "answer" e "hint_values". As energias
## saem de massa, velocidade e altura já arredondadas, e a Em é a soma das parcelas
## arredondadas: assim a conta feita com os números do enunciado dá a resposta certa.
func _build_values(ball_energy: BallEnergy) -> Dictionary:
	var mass := AttributeFormat.round_value(ball_energy.mass)
	var speed := AttributeFormat.round_value(ball_energy.speed)
	var height := AttributeFormat.round_value(ball_energy.height)
	var kinetic := AttributeFormat.round_value(0.5 * mass * speed * speed)
	var potential := AttributeFormat.round_value(mass * PhysicsUnits.GRAVITY * height)
	return {
		"mass": mass,
		"speed": speed,
		"height": height,
		"kinetic_energy": kinetic,
		"potential_energy": potential,
		"total_energy": kinetic + potential,
	}


func _get_value(values: Dictionary, key: String) -> int:
	if not values.has(key):
		push_error("QteQuestionGenerator: valor desconhecido no JSON: '%s'" % key)
		return 0
	return values[key]


func _format_question_text(template: Dictionary, values: Dictionary) -> String:
	var text: String = template.get("text", "")
	if not template.has("hint_values"):
		return text

	var hints: Array = template.get("hint_values", [])
	var hint_values: Array = []
	for hint: String in hints:
		hint_values.append(_get_value(values, hint))

	if hint_values.is_empty():
		return text
	return text % hint_values


## Alternativa errada inteira, diferente da certa e das já sorteadas (em "taken").
func _generate_wrong_answer(correct_value: int, unit: String, min_factor: float, max_factor: float, taken: Array) -> String:
	var base_value := float(correct_value)
	if is_zero_approx(base_value):
		base_value = ZERO_VALUE_OFFSET

	for attempt in 50:
		var factor := _rng.randf_range(min_factor, max_factor)
		if _rng.randf() < 0.5:
			factor = 1.0 / factor
		var wrong_text := _format_value(AttributeFormat.round_value(base_value * factor), unit)
		if not taken.has(wrong_text):
			return wrong_text

	# Valores pequenos (ex.: 1 J) quase não têm vizinhos por fator; anda de 1 em 1.
	for offset in range(1, taken.size() + 2):
		var wrong_text := _format_value(correct_value + offset, unit)
		if not taken.has(wrong_text):
			return wrong_text
	return _format_value(correct_value + taken.size() + 1, unit)


func _format_value(value: int, unit: String) -> String:
	if unit.is_empty():
		return "%d" % value
	return "%d %s" % [value, unit]


func _load_templates() -> void:
	if not FileAccess.file_exists(QUESTIONS_PATH):
		push_error("QteQuestionGenerator: arquivo não encontrado: %s" % QUESTIONS_PATH)
		return

	var file := FileAccess.open(QUESTIONS_PATH, FileAccess.READ)
	if file == null:
		push_error("QteQuestionGenerator: falha ao abrir: %s" % QUESTIONS_PATH)
		return

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("QteQuestionGenerator: erro ao ler JSON: %s" % json.get_error_message())
		return

	if not json.data is Array:
		push_error("QteQuestionGenerator: JSON raiz não é um Array.")
		return

	var data: Array = json.data
	for entry: Dictionary in data:
		_templates.append(entry)
