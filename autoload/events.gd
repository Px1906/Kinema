extends Node
## Singleton global de eventos. Registrar em Projeto > Configurações > Autoload.
## Use sinais aqui para desacoplar sistemas distantes.

signal game_started
signal game_paused(is_paused: bool)
signal player_died
