extends Node

const BUS := &"Music"
const FADE_DB := -80.0
const DEFAULT_CROSSFADE := 1.5

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer


func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_a.bus = BUS
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.bus = BUS
	add_child(_player_b)

	_active_player = _player_a


func play_music(stream: AudioStream, crossfade := DEFAULT_CROSSFADE) -> void:
	if _active_player.stream == stream and _active_player.playing:
		return

	var next := _player_b if _active_player == _player_a else _player_a

	next.stream = stream
	next.volume_db = FADE_DB
	next.play()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(_active_player, "volume_db", FADE_DB, crossfade)
	tween.tween_property(next, "volume_db", 0.0, crossfade)
	tween.chain().tween_callback(_active_player.stop)

	_active_player = next


func stop_music(fade := 1.0) -> void:
	if not _active_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_active_player, "volume_db", FADE_DB, fade)
	tween.tween_callback(_active_player.stop)


func play_oneshot(stream: AudioStream, volume_db := 0.0) -> void:
	var player := AudioStreamPlayer.new()
	player.bus = BUS
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func is_playing() -> bool:
	return _active_player.playing


func get_current_stream() -> AudioStream:
	return _active_player.stream if _active_player.playing else null
