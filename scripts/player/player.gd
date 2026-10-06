extends RigidBody2D
class_name Player

enum State { PREPARANDO, MOVENDO, PAROU }

#@export var radius: float = 20.0
#@export var bounce: float = 0.6
#@export var friction: float = 0.4

var state: State = State.PREPARANDO
