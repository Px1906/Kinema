class_name QteQuestionGenerator
extends RefCounted

const QUESTIONS_PATH := "res://resources/qte_questions.json"
const ZERO_VALUE_OFFSET := 0.5

var _rng := RandomNumberGenerator.new()
var _templates: Array[Dictionary] = []

## Propriedades de BallEnergy que o JSON pode citar em "answer" e "hint_values".
var _property_lookup := {
	"mass": &"mass",
	"speed": &"speed",
	"height": &"height",
	"kinetic_energy": &"kinetic_energy",
	"potential_energy": &"potential_energy",
	"total_energy": &"total_energy",
}


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

	var correct_value := _get_ball_value(template.get("answer", ""), ball_energy)
	var question_text := _format_question_text(template, ball_energy)
	var unit: String = template.get("unit", "")
	var min_factor: float = template.get("wrong_min_factor", 0.3)
	var max_factor: float = template.get("wrong_max_factor", 2.5)

	var correct_answer := _format_value(correct_value, unit)
	var wrong_1 := _generate_wrong_answer(correct_value, unit, min_factor, max_factor, [])
	var wrong_2 := _generate_wrong_answer(correct_value, unit, min_factor, max_factor, [wrong_1])

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


func _get_ball_value(key: String, ball_energy: BallEnergy) -> float:
	var property: StringName = _property_lookup.get(key, &"")
	if property.is_empty():
		push_error("QteQuestionGenerator: valor desconhecido no JSON: '%s'" % key)
		return 0.0
	return ball_energy.get(property)


func _format_question_text(template: Dictionary, ball_energy: BallEnergy) -> String:
	var text: String = template.get("text", "")
	if not template.has("hint_values"):
		return text

	var hints: Array = template.get("hint_values", [])
	var values: Array = []
	for hint: String in hints:
		values.append(_get_ball_value(hint, ball_energy))

	if values.is_empty():
		return text
	return text % values


func _generate_wrong_answer(correct_value: float, unit: String, min_factor: float, max_factor: float, existing_wrong: Array) -> String:
	var base_value := correct_value
	if is_zero_approx(base_value):
		base_value = ZERO_VALUE_OFFSET

	for attempt in 50:
		var factor := _rng.randf_range(min_factor, max_factor)
		if _rng.randf() < 0.5:
			factor = 1.0 / factor
		var wrong_value := base_value * factor
		var wrong_text := _format_value(wrong_value, unit)

		if wrong_text == _format_value(correct_value, unit):
			continue
		if existing_wrong.has(wrong_text):
			continue
		return wrong_text

	return _format_value(base_value * 2.0 + ZERO_VALUE_OFFSET, unit)


func _format_value(value: float, unit: String) -> String:
	var rounded := snappedf(value, 0.1)
	if unit.is_empty():
		return "%.1f" % rounded
	return "%.1f %s" % [rounded, unit]


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
