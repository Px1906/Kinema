extends Node

const BUS := &"UI"
const POOL_SIZE := 4

const HOVER_SFX := preload("res://audio/sfx/ui/hover.wav")
const CLICK_SFX := preload("res://audio/sfx/ui/clik.wav")
const PAUSE_ON_SFX := preload("res://audio/sfx/ui/pause-on.wav")
const PAUSE_OFF_SFX := preload("res://audio/sfx/ui/pause-off.wav")

const HOVER_DB := -12.0
const CLICK_DB := -6.0
const PAUSE_DB := -4.0

var _pool: Array[AudioStreamPlayer] = []
var _index: int = 0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = BUS
		add_child(p)
		_pool.append(p)

	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Button:
		_wire_button(node as Button)


func _wire_button(button: Button) -> void:
	if not button.mouse_entered.is_connected(_on_button_hovered):
		button.mouse_entered.connect(_on_button_hovered)
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)


func _on_button_hovered() -> void:
	_play(HOVER_SFX, HOVER_DB)


func _on_button_pressed() -> void:
	_play(CLICK_SFX, CLICK_DB)


func play_pause(paused: bool) -> void:
	_play(PAUSE_ON_SFX if paused else PAUSE_OFF_SFX, PAUSE_DB)


func _play(stream: AudioStream, volume_db := 0.0) -> void:
	var p := _pool[_index]
	_index = (_index + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.play()
