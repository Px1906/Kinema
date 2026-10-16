class_name QteQuestionGenerator
extends RefCounted

const QUESTIONS_PATH := "res://resources/qte_questions.json"

var _rng := RandomNumberGenerator.new()
var _templates: Array[Dictionary] = []


func _init() -> void:
	_load_templates()


func generate_random(ball_energy: BallEnergy) -> Dictionary:
	_rng.randomize()
	if _templates.is_empty():
		push_error("QteQuestionGenerator: nenhum modelo de pergunta carregado.")
		return {}

	var template: Dictionary = _templates[_rng.randi_range(0, _templates.size() - 1)]
	return _generate_from_template(template, ball_energy)


func _generate_from_template(template: Dictionary, ball_energy: BallEnergy) -> Dictionary:
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
	_shuffle(alternatives)
	var correct_index := alternatives.find(correct_answer)

	return {
		"question": question_text,
		"alternatives": alternatives,
		"correct_index": correct_index,
	}


func _get_value_for_type(question_type: String, ball_energy: BallEnergy) -> float:
	match question_type:
		"KINETIC_ENERGY":
			return ball_energy.kinetic_energy
		"POTENTIAL_ENERGY":
			return ball_energy.potential_energy
		"TOTAL_ENERGY":
			return ball_energy.total_energy
		"SPEED":
			return ball_energy.speed
		"MASS":
			return ball_energy.mass
		_:
			return 0.0


func _format_question_text(template: Dictionary, ball_energy: BallEnergy) -> String:
	var text: String = template.get("text", "")
	if not template.has("hint_values"):
		return text

	var hints: Array = template.get("hint_values", [])
	var values: Array[float] = []
	for hint: String in hints:
		match hint:
			"mass":
				values.append(ball_energy.mass)
			"speed":
				values.append(ball_energy.speed)
			"height":
				values.append(ball_energy.height)
			"kinetic_energy":
				values.append(ball_energy.kinetic_energy)
			"potential_energy":
				values.append(ball_energy.potential_energy)
			"total_energy":
				values.append(ball_energy.total_energy)
			_:
				values.append(0.0)

	match values.size():
		1:
			return text % [values[0]]
		2:
			return text % [values[0], values[1]]
		3:
			return text % [values[0], values[1], values[2]]
		_:
			return text


func _generate_wrong_answer(correct_value: float, unit: String, min_factor: float, max_factor: float, existing_wrong: Array) -> String:
	var attempts := 0
	while attempts < 50:
		attempts += 1
		var factor := _rng.randf_range(min_factor, max_factor)
		if _rng.randf() < 0.5:
			factor = 1.0 / factor
		var wrong_value := correct_value * factor
		if wrong_value < 0.0:
			wrong_value = absf(wrong_value)
		var wrong_text := _format_value(wrong_value, unit)

		if wrong_text == _format_value(correct_value, unit):
			continue
		var is_duplicate := false
		for existing: String in existing_wrong:
			if wrong_text == existing:
				is_duplicate = true
				break
		if is_duplicate:
			continue
		return wrong_text

	return _format_value(correct_value * 2.0, unit)


func _format_value(value: float, unit: String) -> String:
	var rounded := snappedf(value, 0.1)
	if unit.is_empty():
		return "%.1f" % rounded
	return "%.1f %s" % [rounded, unit]


func _shuffle(arr: Array[String]) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp := arr[i]
		arr[i] = arr[j]
		arr[j] = temp


func _load_templates() -> void:
	if not FileAccess.file_exists(QUESTIONS_PATH):
		push_error("QteQuestionGenerator: arquivo não encontrado: %s" % QUESTIONS_PATH)
		return

	var file := FileAccess.open(QUESTIONS_PATH, FileAccess.READ)
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("QteQuestionGenerator: erro ao ler JSON: %s" % json.get_error_message())
		return

	var data: Array = json.data
	for entry: Dictionary in data:
		_templates.append(entry)
