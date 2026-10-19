extends Node
## Singleton global de eventos. Registrar em Projeto > Configurações > Autoload.
## Use sinais aqui para desacoplar sistemas distantes.

const OBSTACLE_GROUP: StringName = &"obstacle"

signal game_started
signal game_paused(is_paused: bool)
signal player_died

signal qte_started(barrier: QteBarrier)
signal qte_finished(barrier: QteBarrier, correct: bool)
