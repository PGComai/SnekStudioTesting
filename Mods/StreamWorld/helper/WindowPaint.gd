extends Window


const BRUSH_SIZE: float = 10.0
const ERASER_SIZE: Vector2 = Vector2(200.0, 100.0)


var img: Image
var img_tex: ImageTexture
var drags: Dictionary[String, PackedVector2Array] = {}
var erasings: PackedVector2Array = []


@onready var texture_rect: TextureRect = $TextureRect
@onready var capture_scene: CaptureScene = $".."


func _ready() -> void:
	img = Image.create_empty(3840.0, 2160.0, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	img_tex = ImageTexture.create_from_image(img)
	texture_rect.texture = img_tex


func _process(delta: float) -> void:
	var img_changed := false
	if drags.size():
		var new_drags: Dictionary[String, PackedVector2Array] = {}
		for id: String in drags.keys():
			var drag: PackedVector2Array = drags[id]
			if drag.size() > 1:
				img_changed = true
				var clr: Color = capture_scene.colors[id]
				for i: int in drag.size():
					if i < drag.size() - 1:
						for pixel: Vector2i in Geometry2D.bresenham_line(
								Vector2i(drag[i]),
								Vector2i(drag[i+1])
							):
							_brush_at(pixel, clr)
			else:
				new_drags[id] = drag
		drags = new_drags
	if erasings.size():
		img_changed = true
		for erase_px: Vector2 in erasings:
			_erase_at(erase_px - (ERASER_SIZE / 2.0))
		erasings = []
	if img_changed:
		img_tex.update(img)


func _brush_at(_position: Vector2, clr: Color) -> void:
	img.fill_rect(Rect2(_position, Vector2.ONE).grow(BRUSH_SIZE), clr)

func _erase_at(_position: Vector2) -> void:
	img.fill_rect(Rect2(_position, ERASER_SIZE), Color.TRANSPARENT)


#func _on_green_heat_click_received(packet: Dictionary) -> void:
	#handle_common(packet)
#
#
##{ "mobile": false, "id": "AWP-r4WBz6ultU20RPT9z", "x": 0.61295180722892,
##"y": 0.50670241286863, "button": "left", "shift": false, "ctrl": false,
##"alt": false, "time": 1769906585726.0, "latency": 3.537, "type": "drag" }
#func _on_green_heat_drag_received(packet: Dictionary) -> void:
	#handle_common(packet)
	#if drags.has(packet.id):
		#var drag: PackedVector2Array = drags[packet.id]
		##drag.append()
	#else:
		#pass
#
#
#func _on_green_heat_hover_received(packet: Dictionary) -> void:
	#handle_common(packet)
#
#
#func _on_green_heat_release_received(packet: Dictionary) -> void:
	#handle_common(packet)


func _on_node_3d_screen_interacted(packet: Dictionary, virtual_screen_pos: Vector2) -> void:
	if packet.type == "drag":
		if drags.has(packet.id):
			var drag: PackedVector2Array = drags[packet.id]
			drag.append(virtual_screen_pos)
			drags[packet.id] = drag
		else:
			drags[packet.id] = PackedVector2Array([virtual_screen_pos])
	elif packet.type == "release":
		if drags.has(packet.id):
			drags.erase(packet.id)


func _on_window_eraser_erasing(absolute_pos: Vector2i) -> void:
	if absolute_pos.x > 1080 - 100:
		erasings.append(Vector2(absolute_pos) - Vector2(1080.0, 0.0))
		#print(Vector2(absolute_pos) + (ERASER_SIZE / 2.0) - Vector2(1080.0, 0.0))
