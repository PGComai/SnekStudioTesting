extends Window
class_name WindowPaint

#TODO temp clear (hide palette selector as well)


signal debug_click(pos: Vector2)
signal debug_thread_click(pos: Vector2)
signal debug_clear


const BRUSH_ROUND_SIZE: int = 10
const BRUSH_SIZE: float = 5.0
const BRUSH_SIZE_THICK: float = 25.0
const ERASER_SIZE: Vector2 = Vector2(200.0, 100.0)
const ERASER_SIZE_MOD: Vector2 = Vector2(100.0, 100.0)
const SAVED_DRAWINGS_DIR: String = "user://drawings"


var img: Image
var img_tex: ImageTexture
var img_fade: Image
var img_fade_mask: Image
var img_fade_mask_fade: Image
var drags: Dictionary[String, PackedVector2Array] = {}
var mod_erasings: Dictionary[String, PackedVector2Array] = {}
var erasings: PackedVector2Array = []
var drags_thread: Dictionary[String, PackedVector2Array] = {}
var mod_erasings_thread: Dictionary[String, PackedVector2Array] = {}
var erasings_thread: PackedVector2Array = []
var brush_thickness: float = BRUSH_SIZE

var mutex: Mutex
var semaphore: Semaphore
var thread: Thread
var exit_thread := false
var queue_thread := false
var thread_needed := false
var done_erasing := true
var clear_queued := false
var brush_round: Image
var brush_round_mask: Image
var thread_rng: RandomNumberGenerator


@onready var texture_rect: TextureRect = $TextureRect
@onready var capture_scene: CaptureScene = $".."
@onready var texture_rect_shadow: TextureRect = $TextureRectShadow


func _ready() -> void:
	#var temp_size: int = BRUSH_ROUND_SIZE / 2
	
	#brush_round_mask.resize(BRUSH_ROUND_SIZE, BRUSH_ROUND_SIZE, Image.INTERPOLATE_BILINEAR)
	
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	exit_thread = true
	thread_rng = RandomNumberGenerator.new()
	
	thread = Thread.new()
	thread.start(_thread_function, Thread.PRIORITY_HIGH)
	
	img = Image.create_empty(3840.0, 2160.0, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	img_tex = ImageTexture.create_from_image(img)
	texture_rect.texture = img_tex
	texture_rect_shadow.texture = img_tex
	
	img_fade = Image.create_empty(3840.0, 2160.0, false, Image.FORMAT_RGBA8)
	img_fade.fill(Color(0.0, 0.0, 0.0, 0.0))
	img_fade_mask = Image.create_empty(3840.0, 2160.0, false, Image.FORMAT_LA8)
	img_fade_mask.fill(Color(0.0, 0.0, 0.0, 0.0))
	img_fade_mask_fade = Image.create_empty(3840.0, 2160.0, false, Image.FORMAT_LA8)
	img_fade_mask_fade.fill(Color(0.0, 0.0, 0.0, 1.0))


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
		
		erasings_thread = erasings.duplicate()
		drags_thread = drags.duplicate()
		mod_erasings_thread = mod_erasings.duplicate()
		drags.clear()
		erasings.clear()
		mod_erasings.clear()
		
		mutex.lock()
		
		for id: String in drags_thread:
			var drag: PackedVector2Array = drags_thread[id]
			drags[id] = PackedVector2Array([drag[-1]])
		if erasings_thread.size():
			erasings.append(erasings_thread[-1])
		for id: String in mod_erasings_thread:
			var mod_erasing: PackedVector2Array = mod_erasings_thread[id]
			mod_erasings[id] = PackedVector2Array([mod_erasing[-1]])
		
		var brushes_thread: Dictionary[String, Brush] = capture_scene.brushes.duplicate(true)
		
		if clear_queued:
			img.fill(Color(0.0, 0.0, 0.0, 0.0))
			img_tex.update.call_deferred(img)
			clear_queued = false
			erasings_thread.clear()
			drags_thread.clear()
			mod_erasings_thread.clear()
		else:
			var img_changed := false
			if drags_thread.size():
				for id: String in drags_thread.keys():
					var drag: PackedVector2Array = drags_thread[id]
					if drag.size() > 1:
						img_changed = true
						var drag_brush: Brush = brushes_thread[id]
						var new_drag := PackedVector2Array([])
						for i: int in drag.size():
							if i < drag.size() - 1:
								if drag_brush.sparse:
									var sparse: int = 0
									for pixel: Vector2i in Geometry2D.bresenham_line(
											Vector2i(drag[i]),
											Vector2i(drag[i+1])
										):
										if sparse % drag_brush.sparse == 0:
											_brush_at(pixel, drag_brush.brush_image, drag_brush.brush_mask, drag_brush.splatter)
										sparse += 1
								else:
									for pixel: Vector2i in Geometry2D.bresenham_line(
											Vector2i(drag[i]),
											Vector2i(drag[i+1])
										):
										_brush_at(pixel, drag_brush.brush_image, drag_brush.brush_mask, drag_brush.splatter)
							else:
								new_drag.append(drag[i])
			
			if mod_erasings_thread.size():
				for id: String in mod_erasings_thread.keys():
					var drag: PackedVector2Array = mod_erasings_thread[id]
					if drag.size() > 1:
						img_changed = true
						var new_drag := PackedVector2Array([])
						for i: int in drag.size():
							if i < drag.size() - 1:
								for pixel: Vector2i in Geometry2D.bresenham_line(
										Vector2i(drag[i]),
										Vector2i(drag[i+1])
									):
									_mod_erase_at(Vector2(pixel) - (ERASER_SIZE_MOD / 2.0))
							else:
								new_drag.append(drag[i])
			
			if erasings_thread.size():
				if erasings_thread.size() > 1:
					img_changed = true
					for i: int in erasings_thread.size():
						if i < erasings_thread.size() - 1:
							for erase_px: Vector2i in Geometry2D.bresenham_line(
									Vector2i(erasings_thread[i]),
									Vector2i(erasings_thread[i+1])
								):
								_erase_at(Vector2(erase_px) - (ERASER_SIZE / 2.0))
			
			#img_fade_mask.blend_rect(
							#img_fade_mask_fade,
							#Rect2i(Vector2i(0, 0), Vector2i(3840, 2160)),
							#Vector2i(0, 0)
							#)
			#img.blend_rect_mask(
							#img_fade,
							#img_fade_mask,
							#Rect2i(Vector2i(0, 0), Vector2i(3840, 2160)),
							#Vector2i(0, 0)
							#)
			#img.blit_rect_mask(
							#img_fade,
							#img_fade_mask,
							#Rect2i(Vector2i(0, 0), Vector2i(3840, 2160)),
							#Vector2i(0, 0)
							#)
			
			if img_changed:
				img_tex.update.call_deferred(img)
		
		
		mutex.unlock()
		
		mutex.lock()
		exit_thread = true
		mutex.unlock()


func color_brush(brush: Image, clr: Color) -> Image:
	var brush_img: Image = brush.duplicate()
	var brush_size: Vector2i = brush_img.get_size()
	for x in brush_size.x:
		for y in brush_size.y:
			var pixel_color: Color = clr
			pixel_color.a = brush.get_pixel(x, y).a
			brush_img.set_pixel(x, y, pixel_color)
	
	return brush_img


func _process(delta: float) -> void:
	if queue_thread:
		if exit_thread:
			exit_thread = false
			semaphore.post()
			queue_thread = false


func _brush_at(_position: Vector2, brush: Image, brush_mask: Image, brush_splatter: float) -> void:
	if brush_splatter:
		_position += Vector2(thread_rng.randfn(0.0, brush_splatter), thread_rng.randfn(0.0, brush_splatter))
	var brush_size: Vector2i = brush.get_size()
	img.blend_rect_mask(brush, brush_mask, Rect2i(Vector2i.ZERO, brush_size), Vector2i(_position) - (brush_size / 2))
	#img.fill_rect(Rect2(_position, Vector2.ONE).grow(brush_thickness), clr)


func _erase_at(_position: Vector2) -> void:
	img.fill_rect(Rect2(_position, ERASER_SIZE), Color.TRANSPARENT)


func _mod_erase_at(_position: Vector2) -> void:
	img.fill_rect(Rect2(_position, ERASER_SIZE_MOD), Color.TRANSPARENT)


func clear() -> void:
	clear_queued = true
	thread_needed = true
	debug_clear.emit()


func _on_node_3d_screen_interacted(
								packet: Dictionary,
								virtual_screen_pos: Vector2,
								eraser: bool
								) -> void:
	if eraser:
		if packet.type == "drag":
			if mod_erasings.has(packet.id):
				var drag: PackedVector2Array = mod_erasings[packet.id]
				drag.append(virtual_screen_pos)
				mod_erasings[packet.id] = drag
			else:
				mod_erasings[packet.id] = PackedVector2Array([virtual_screen_pos])
			thread_needed = true
		elif packet.type == "release":
			if mod_erasings.has(packet.id):
				mod_erasings.erase(packet.id)
	else:
		if packet.type == "drag" or packet.type == "click":
			if drags.has(packet.id):
				var drag: PackedVector2Array = drags[packet.id]
				drag.append(virtual_screen_pos)
				drags[packet.id] = drag
			else:
				if packet.type == "drag":
					drags[packet.id] = PackedVector2Array([virtual_screen_pos])
				elif packet.type == "click":
					drags[packet.id] = PackedVector2Array([virtual_screen_pos, virtual_screen_pos])
			#debug_click.emit(virtual_screen_pos)
			thread_needed = true
		elif packet.type == "release":
			if drags.has(packet.id):
				drags.erase(packet.id)


func _on_capture_scene_user_released(id: String) -> void:
	if drags.has(id):
		drags.erase(id)


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


func _on_timer_fade_timeout() -> void:
	pass
	#if thread_needed:
		#if exit_thread:
			#exit_thread = false
			#semaphore.post()
		#else:
			#queue_thread = true
		#thread_needed = false


func _on_capture_scene_save_drawing() -> void:
	var drawings_dir: DirAccess
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SAVED_DRAWINGS_DIR)):
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SAVED_DRAWINGS_DIR))
	drawings_dir = DirAccess.open(SAVED_DRAWINGS_DIR)
	var num_files: int = drawings_dir.get_files().size()
	var filename: String = "drawing%s.png" % num_files
	img.save_png(SAVED_DRAWINGS_DIR.path_join(filename))
