class_name Player
extends CharacterBody2D
## Controlador básico do jogador (exemplo). Ajuste ao seu jogo.

signal health_changed(new_health: int)

@export var speed: float = 200.0
@export var max_health: int = 100

var health: int = max_health:
	set(value):
		health = clampi(value, 0, max_health)
		health_changed.emit(health)
		if health == 0:
			Events.player_died.emit()


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
