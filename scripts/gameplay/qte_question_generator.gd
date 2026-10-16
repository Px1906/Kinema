class_name QteQuestionGenerator
extends RefCounted

var _rng := RandomNumberGenerator.new()


func generate(template: QteQuestionTemplate, ball_energy: BallEnergy) -> Dictionary:
	_rng.randomize()
	var correct_value := template.get_correct_answer(ball_energy)
	var question_text := template.format_question(ball_energy)
	var unit := template.unit

	var correct_answer := _format_value(correct_value, unit)
	var wrong_1 := _generate_wrong_answer(correct_value, unit, template, [])
	var wrong_2 := _generate_wrong_answer(correct_value, unit, template, [wrong_1])

	var alternatives: Array[String] = [correct_answer, wrong_1, wrong_2]
	var correct_index := 0

	_shuffle_alternatives(alternatives)
	correct_index = alternatives.find(correct_answer)

	return {
		"question": question_text,
		"alternatives": alternatives,
		"correct_index": correct_index,
	}


func _generate_wrong_answer(correct_value: float, unit: String, template: QteQuestionTemplate, existing_wrong: Array) -> String:
	var min_factor := template.wrong_answer_min_factor
	var max_factor := template.wrong_answer_max_factor
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
		var correct_text := _format_value(correct_value, unit)

		if wrong_text == correct_text:
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


func _shuffle_alternatives(alternatives: Array[String]) -> void:
	for i in range(alternatives.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp := alternatives[i]
		alternatives[i] = alternatives[j]
		alternatives[j] = temp
