class_name SpikeZone
extends Zone
## Espinhos: a bola que entra finca, freando até parar um pouco além do ponto de
## contato, fica presa um instante e a tentativa falha como numa batida em obstáculo.
## Tamanho fixo de 128×32 para casar com o sprite: repita lado a lado nos trechos
## longos e gire o nó para usar em paredes e tetos (as pontas apontam para -y local).

@export_category("Stick")
## Tempo da freada até parar, em segundos, antes do limite de profundidade.
@export var stop_duration: float = 0.12
## Quanto a bola entra, no máximo, além do ponto de contato, em px.
@export var max_depth: float = 12.0
## Quanto tempo a bola fica presa antes de a tentativa falhar, em segundos.
@export var hold_time: float = 0.5


func _ready() -> void:
	super._ready()
	player_entered.connect(_on_player_entered)


func _on_player_entered(player: Player) -> void:
	# Adiado: congelar o corpo dentro do body_entered falha durante a etapa de física.
	player.stick_into.call_deferred(stop_duration, max_depth, hold_time)
