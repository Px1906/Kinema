class_name QteQuestionGenerator
extends RefCounted

const QUESTIONS_PATH := "res://resources/qte_questions.json"
const ZERO_VALUE_OFFSET := 0.5

var _rng := RandomNumberGenerator.new()
var _templates: Array[Dictionary] = []

var _value_lookup := {
	"KINETIC_ENERGY": &"kinetic_energy",
	"POTENTIAL_ENERGY": &"potential_energy",
	"TOTAL_ENERGY": &"total_energy",
	"SPEED": &"speed",
	"MASS": &"mass",
}

var _hint_lookup := {
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


func generate_random(ball_energy: BallEnergy) -> Dictionary:
	if _templates.is_empty():
		push_error("QteQuestionGenerator: nenhum modelo de pergunta carregado.")
		return {}

	var template: Dictionary = _templates[_rng.randi_range(0, _templates.size() - 1)]
	return _generate_from_template(template, ball_energy)


func _generate_from_template(template: Dictionary, ball_energy: BallEnergy) -> Dictionary:
	if template.has("alternatives"):
		return _generate_fixed(template)

	var question_type: String = template.get("type", "")
	var correct_value := _get_value_for_type(question_type, ball_energy)
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
		"show_attributes": true,
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


func _get_value_for_type(question_type: String, ball_energy: BallEnergy) -> float:
	var property: StringName = _value_lookup.get(question_type, &"")
	if property.is_empty():
		return 0.0
	return ball_energy.get(property)


func _format_question_text(template: Dictionary, ball_energy: BallEnergy) -> String:
	var text: String = template.get("text", "")
	if not template.has("hint_values"):
		return text

	var hints: Array = template.get("hint_values", [])
	var values: Array = []
	for hint: String in hints:
		var property: StringName = _hint_lookup.get(hint, &"")
		if property.is_empty():
			values.append(0.0)
		else:
			values.append(ball_energy.get(property))

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
