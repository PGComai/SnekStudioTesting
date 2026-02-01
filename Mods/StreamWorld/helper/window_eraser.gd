extends Window


signal erasing(absolute_pos: Vector2i)


var held := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			held = event.pressed


func _process(delta: float) -> void:
	if held:
		position = DisplayServer.mouse_get_position() - (size / 2)
		erasing.emit(position)
