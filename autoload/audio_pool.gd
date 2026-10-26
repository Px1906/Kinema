class_name AudioPool
extends Node

var _players: Array[AudioStreamPlayer] = []
var _index: int = 0


func _init_pool(bus: StringName, size: int) -> void:
	for i in size:
		var player := AudioStreamPlayer.new()
		player.bus = bus
		add_child(player)
		_players.append(player)


func play(stream: AudioStream, volume_db := 0.0, pitch_scale := 1.0) -> void:
	var player := _players[_index]
	_index = (_index + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func play_random_pitch(stream: AudioStream, min_pitch := 0.9, max_pitch := 1.1, volume_db := 0.0) -> void:
	play(stream, volume_db, randf_range(min_pitch, max_pitch))
