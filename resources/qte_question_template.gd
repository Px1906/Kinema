class_name QteQuestionTemplate
extends Resource

enum QuestionType {
	KINETIC_ENERGY,
	POTENTIAL_ENERGY,
	TOTAL_ENERGY,
	SPEED,
	MASS,
}

@export var question_type: QuestionType = QuestionType.KINETIC_ENERGY
@export var question_text: String = ""
@export var unit: String = ""
@export_range(0.1, 2.0) var wrong_answer_min_factor: float = 0.3
@export_range(1.1, 5.0) var wrong_answer_max_factor: float = 2.5


func get_correct_answer(ball_energy: BallEnergy) -> float:
	match question_type:
		QuestionType.KINETIC_ENERGY:
			return ball_energy.kinetic_energy
		QuestionType.POTENTIAL_ENERGY:
			return ball_energy.potential_energy
		QuestionType.TOTAL_ENERGY:
			return ball_energy.total_energy
		QuestionType.SPEED:
			return ball_energy.speed
		QuestionType.MASS:
			return ball_energy.mass
		_:
			return 0.0


func format_question(ball_energy: BallEnergy) -> String:
	if not question_text.is_empty():
		return question_text

	match question_type:
		QuestionType.KINETIC_ENERGY:
			return "Qual é a energia cinética da bola? (m=%.1f kg, v=%.1f m/s)" % [ball_energy.mass, ball_energy.speed]
		QuestionType.POTENTIAL_ENERGY:
			return "Qual é a energia potencial da bola? (m=%.1f kg, h=%.1f m)" % [ball_energy.mass, ball_energy.height]
		QuestionType.TOTAL_ENERGY:
			return "Qual é a energia mecânica total da bola?"
		QuestionType.SPEED:
			return "Qual é a velocidade da bola?"
		QuestionType.MASS:
			return "Qual é a massa da bola?"
		_:
			return ""
