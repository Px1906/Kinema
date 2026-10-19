extends Node

const BUS := &"SFX"
const POOL_SIZE := 16

var _players: Array[AudioStreamPlayer] = []
var _index: int = 0


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		_players.append(player)


func play(stream: AudioStream, volume_db := 0.0, pitch_scale := 1.0) -> void:
	var player := _players[_index]
	_index = (_index + 1) % POOL_SIZE

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func play_random_pitch(stream: AudioStream, min_pitch := 0.9, max_pitch := 1.1) -> void:
	play(stream, 0.0, randf_range(min_pitch, max_pitch))
