class_name DragHandle
extends Node
## Permite arrastar um Control (target) pela tela segurando outro Control (handle).
## Um clique sem arrastar continua funcionando normalmente no handle (ex.: botão de
## abrir o popup); só vira arrasto depois que o mouse se move mais que drag_threshold.

## Control que o jogador segura para arrastar (ex.: a alça DragGrip do popup).
@export var handle: Control
## Control que se move. Se vazio, usa o nó pai do DragHandle.
@export var target: Control
## Distância em pixels que o mouse precisa andar para o clique virar arrasto.
@export_range(0.0, 32.0, 1.0) var drag_threshold: float = 6.0

var _pressing := false
var _dragging := false
var _press_mouse_position := Vector2.ZERO
var _press_target_position := Vector2.ZERO


func _ready() -> void:
	if target == null:
		target = get_parent() as Control
	if handle == null or target == null:
		push_warning("DragHandle: assign the 'Handle' and 'Target' properties in the Inspector.")
		return

	handle.gui_input.connect(_on_handle_gui_input)


func _on_handle_gui_input(event: InputEvent) -> void:
	var button_event := event as InputEventMouseButton
	if button_event != null and button_event.button_index == MOUSE_BUTTON_LEFT:
		if button_event.pressed:
			_start_press()
		else:
			_finish_press()
		return

	if event is InputEventMouseMotion and _pressing:
		_update_drag()


func _start_press() -> void:
	_pressing = true
	_dragging = false
	_press_mouse_position = target.get_global_mouse_position()
	_press_target_position = target.global_position


func _update_drag() -> void:
	var mouse_offset := target.get_global_mouse_position() - _press_mouse_position
	if not _dragging:
		if mouse_offset.length() < drag_threshold:
			return
		_dragging = true
		target.move_to_front()

	target.global_position = _clamp_to_screen(_press_target_position + mouse_offset)


func _finish_press() -> void:
	_pressing = false
	if not _dragging:
		return

	_dragging = false
	# O sinal gui_input chega antes do Button: aceitar o evento impede o clique (toggle)
	# e soltar o foco limpa o estado visual de "pressionado" do botão.
	handle.accept_event()
	handle.release_focus()


func _clamp_to_screen(target_position: Vector2) -> Vector2:
	var screen_size := target.get_viewport_rect().size
	var max_position := (screen_size - target.size).max(Vector2.ZERO)
	return target_position.clamp(Vector2.ZERO, max_position)
