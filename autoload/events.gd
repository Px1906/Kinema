extends Node
## Singleton global de eventos. Registrar em Projeto > Configurações > Autoload.
## Use sinais aqui para desacoplar sistemas distantes.

const OBSTACLE_GROUP: StringName = &"obstacle"

signal game_started
signal game_paused(is_paused: bool)
signal player_died

signal qte_started(barrier: Node2D)
signal qte_answered(barrier: Node2D, correct: bool)
signal qte_timeout(barrier: Node2D)
signal barrier_removed(barrier: Node2D)
