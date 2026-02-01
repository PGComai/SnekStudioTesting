extends Window
class_name WindowPaint


const BRUSH_SIZE: float = 5.0
const BRUSH_SIZE_THICK: float = 25.0
const ERASER_SIZE: Vector2 = Vector2(200.0, 100.0)


var img: Image
var img_tex: ImageTexture
var drags: Dictionary[String, PackedVector2Array] = {}
var erasings: PackedVector2Array = []
var drags_thread: Dictionary[String, PackedVector2Array] = {}
var erasings_thread: PackedVector2Array = []
var brush_thickness: float = BRUSH_SIZE

var mutex: Mutex
var semaphore: Semaphore
var thread: Thread
var exit_thread := false
var queue_thread := false
var thread_needed := false
var done_erasing := true


@onready var texture_rect: TextureRect = $TextureRect
@onready var capture_scene: CaptureScene = $".."


func _ready() -> void:
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	exit_thread = true
	
	thread = Thread.new()
	thread.start(_thread_function, Thread.PRIORITY_LOW)
	
	img = Image.create_empty(3840.0, 2160.0, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	img_tex = ImageTexture.create_from_image(img)
	texture_rect.texture = img_tex


func _on_tree_exiting():
	if not Engine.is_editor_hint() and mutex:
		mutex.lock()
		exit_thread = true # Protect with Mutex.
		mutex.unlock()

		# Unblock by posting.
		semaphore.post()

		# Wait until it exits.
		thread.wait_to_finish()


func _thread_function() -> void:
	while true:
		semaphore.wait()
		
		mutex.lock()
		var should_exit = exit_thread
		mutex.unlock()
		
		if should_exit:
			break
		
		
		mutex.lock()
		
		erasings_thread = erasings.duplicate()
		drags_thread = drags.duplicate()
		
		var img_changed := false
		if drags_thread.size():
			var new_drags: Dictionary[String, PackedVector2Array] = {}
			for id: String in drags_thread.keys():
				var drag: PackedVector2Array = drags_thread[id]
				if drag.size() > 1:
					img_changed = true
					var clr: Color = capture_scene.colors[id]
					var new_drag := PackedVector2Array([])
					for i: int in drag.size():
						if i < drag.size() - 1:
							for pixel: Vector2i in Geometry2D.bresenham_line(
									Vector2i(drag[i]),
									Vector2i(drag[i+1])
								):
								_brush_at(pixel, clr)
						else:
							new_drag.append(drag[i])
						new_drags[id] = new_drag
				else:
					new_drags[id] = drag
			drags_thread = new_drags
		
		if erasings_thread.size():
			var new_erasings := PackedVector2Array([])
			if erasings_thread.size() > 1:
				img_changed = true
				for i: int in erasings_thread.size():
					if i < erasings_thread.size() - 1:
						for erase_px: Vector2i in Geometry2D.bresenham_line(
								Vector2i(erasings_thread[i]),
								Vector2i(erasings_thread[i+1])
							):
							_erase_at(Vector2(erase_px) - (ERASER_SIZE / 2.0))
					else:
						new_erasings.append(erasings_thread[i])
				erasings_thread = new_erasings
		if img_changed:
			img_tex.update.call_deferred(img)
		
		
		mutex.unlock()
		
		drags = drags_thread.duplicate()
		erasings = erasings_thread.duplicate()
		
		mutex.lock()
		exit_thread = true
		mutex.unlock()


func _process(delta: float) -> void:
	if queue_thread:
		if exit_thread:
			exit_thread = false
			semaphore.post()
			queue_thread = false


func _brush_at(_position: Vector2, clr: Color) -> void:
	img.fill_rect(Rect2(_position, Vector2.ONE).grow(brush_thickness), clr)

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
		thread_needed = true
	elif packet.type == "release":
		if drags.has(packet.id):
			drags.erase(packet.id)


func _on_window_eraser_erasing(absolute_pos: Vector2i) -> void:
	if absolute_pos.x > 1080 - 100:
		if done_erasing:
			erasings = []
		erasings.append(Vector2(absolute_pos) - Vector2(1080.0, 0.0) + (ERASER_SIZE / 2.0))
		thread_needed = true
		done_erasing = false


func _on_window_eraser_erasing_done() -> void:
	done_erasing = true


func _on_timer_thread_timeout() -> void:
	if thread_needed:
		if exit_thread:
			exit_thread = false
			semaphore.post()
		else:
			queue_thread = true
		thread_needed = false
