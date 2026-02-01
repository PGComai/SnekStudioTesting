extends Window


const ERASER_HOME: Vector2 = Vector2(440.0, 0.0)


signal erasing(absolute_pos: Vector2i)
signal erasing_done


var held := false


@onready var texture_rect: TextureRect = $TextureRect


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			held = event.pressed
			if not held:
				position = ERASER_HOME
				erasing_done.emit()
				texture_rect.visible = true
			else:
				texture_rect.visible = false


func _process(delta: float) -> void:
	if held:
		position = DisplayServer.mouse_get_position() - (size / 2)
		erasing.emit(position)
