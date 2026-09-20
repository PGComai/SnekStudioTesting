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
const DRAWING_CACHE_FILE: String = "user://drawing.png"
const DRAWING_FADE_CACHE_FILE: String = "user://drawing_fade_mask.png"


var img: Image
var img_tex: ImageTexture
var fade_tex: ImageTexture
var fade_swap_tex: ImageTexture
var img_fade: Image
var img_fade_mask: Image
var img_fade_mask_fade: Image
var img_fade_swap: Image
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
var fade_queued := false
var brush_round: Image
var brush_round_mask: Image
var thread_rng: RandomNumberGenerator
var last_cache: int


@onready var texture_rect: TextureRect = $TextureRect
@onready var capture_scene: CaptureScene = $".."
@onready var texture_rect_shadow: TextureRect = $TextureRectShadow


func _ready() -> void:
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	exit_thread = true
	thread_rng = RandomNumberGenerator.new()
	
	thread = Thread.new()
	thread.start(_thread_function, Thread.PRIORITY_HIGH)
	
	var loaded_cached: bool = load_cached_drawing()
	if not loaded_cached:
		img = Image.create_empty(3840, 2160, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.0, 0.0, 0.0, 0.0))
		img_fade_mask = Image.create_empty(3840, 2160, false, Image.FORMAT_LA8)
		img_fade_mask.fill(Color(0.0, 0.0, 0.0, 1.0))
	img_tex = ImageTexture.create_from_image(img)
	texture_rect.texture = img_tex
	texture_rect_shadow.texture = img_tex
	
	img_fade = Image.create_empty(3840, 2160, false, Image.FORMAT_RGBA8)
	img_fade.fill(Color(0.0, 0.0, 0.0, 0.0))
	
	fade_tex = ImageTexture.create_from_image(img_fade_mask)
	
	#img_fade_swap = Image.create_empty(3840.0, 2160.0, false, Image.FORMAT_LA8)
	#img_fade_swap.fill(Color(0.0, 0.0, 0.0, 0.0))
	#fade_swap_tex = ImageTexture.create_from_image(img_fade_swap)
	%TextureRectTime.texture = fade_tex
	#%TextureRectTimeSwap.texture = fade_swap_tex
	
	img_fade_mask_fade = Image.create_empty(3840, 2160, false, Image.FORMAT_LA8)
	img_fade_mask_fade.fill(Color(0.0, 0.0, 0.0, 0.01))
	
	last_cache = Time.get_ticks_msec()


func cache_drawing() -> void:
	last_cache = Time.get_ticks_msec()
	img.save_png(DRAWING_CACHE_FILE)
	img_fade_mask.save_png(DRAWING_FADE_CACHE_FILE)
	print("cached drawing")


func load_cached_drawing() -> bool:
	if FileAccess.file_exists(DRAWING_CACHE_FILE):
		var modified_time: int = FileAccess.get_modified_time(DRAWING_CACHE_FILE)
		var current_time: int = int(Time.get_unix_time_from_system())
		var diff: int = current_time - modified_time
		if diff < 21600:
			img = Image.load_from_file(DRAWING_CACHE_FILE)
			if FileAccess.file_exists(DRAWING_FADE_CACHE_FILE):
				img_fade_mask = Image.load_from_file(DRAWING_FADE_CACHE_FILE)
			return true
	return false


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
		
		
		for id: String in drags_thread:
			var drag: PackedVector2Array = drags_thread[id]
			drags[id] = PackedVector2Array([drag[-1]])
		if erasings_thread.size():
			erasings.append(erasings_thread[-1])
		for id: String in mod_erasings_thread:
			var mod_erasing: PackedVector2Array = mod_erasings_thread[id]
			mod_erasings[id] = PackedVector2Array([mod_erasing[-1]])
		
		var brushes_thread: Dictionary[String, Brush] = capture_scene.brushes.duplicate(true)
		for id: String in brushes_thread:
			var brush: Brush = brushes_thread[id]
			if not brush.brush_image:
				brush.make_brush()
				print("MADE BRUSH BUT SHOULDNT HAVE NEEDED TO")#TODO
		
		mutex.lock()
		
		var did_a_fade := false
		var img_changed := false
		if clear_queued:
			img.fill(Color(0.0, 0.0, 0.0, 0.0))
			img_fade_mask.fill(Color.BLACK)
			img_tex.update.call_deferred(img)
			fade_tex.update.call_deferred(img_fade_mask)
			clear_queued = false
			fade_queued = false
			erasings_thread.clear()
			drags_thread.clear()
			mod_erasings_thread.clear()
		else:
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
											if drag_brush.type == Brush.BrushType.CUSTOM_TILE:
												drag_brush.tiling_offset = pixel
												drag_brush.render_offset()
											var desired_mask: Image
											if drag_brush.custom_secondary_mask:
												desired_mask = drag_brush.custom_secondary_mask
											else:
												desired_mask = drag_brush.brush_mask
											_brush_at(pixel, drag_brush.brush_image, desired_mask, drag_brush.splatter)
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
			if img_changed:
				if not fade_queued:
					img_tex.update.call_deferred(img)
					fade_tex.update.call_deferred(img_fade_mask)
		if fade_queued:
			fade_queued = false
			img_fade_mask.blend_rect(img_fade_mask_fade, Rect2i(Vector2i.ZERO, img_fade_mask_fade.get_size()), Vector2i.ZERO)
			if not img_changed:
				img = blend_alpha_mask(img, img_fade_mask)
				img_tex.update.call_deferred(img)
			fade_tex.update.call_deferred(img_fade_mask)
			did_a_fade = true
		
		mutex.unlock()
		
		mutex.lock()
		exit_thread = true
		mutex.unlock()


func swap_la(image: Image) -> Image:
	var data: PackedByteArray = image.get_data()
	data.bswap16()
	return Image.create_from_data(image.get_size().x, image.get_size().y, false, Image.FORMAT_LA8, data)


static func blend_alpha_mask(image: Image, mask: Image) -> Image:
	var image_data: PackedByteArray = image.get_data()
	var mask_data: PackedByteArray = mask.get_data()
	for ia: int in image_data.size() / 4:
		var idx_image: int = (ia * 4) + 3
		var idx_mask: int = ia * 2
		image_data.encode_u8(idx_image, mask_data.decode_u8(idx_mask))
	return Image.create_from_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, image_data)


func color_brush(brush: Image, clr: Color) -> Image:
	var brush_img: Image = brush.duplicate()
	var brush_size: Vector2i = brush_img.get_size()
	for x: int in brush_size.x:
		for y: int in brush_size.y:
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


func _brush_at(_position: Vector2, brush_img: Image, brush_mask: Image, brush_splatter: float) -> void:
	if brush_splatter:
		_position += Vector2(thread_rng.randfn(0.0, brush_splatter), thread_rng.randfn(0.0, brush_splatter))
	var brush_size: Vector2i = brush_img.get_size()
	img.blend_rect_mask(brush_img, brush_mask, Rect2i(Vector2i.ZERO, brush_size), Vector2i(_position) - (brush_size / 2))
	img_fade_mask.blend_rect(brush_mask, Rect2i(Vector2i.ZERO, brush_size), Vector2i(_position) - (brush_size / 2))
	#img.fill_rect(Rect2(_position, Vector2.ONE).grow(brush_thickness), clr)


func _erase_at(_position: Vector2) -> void:
	img.fill_rect(Rect2(_position, ERASER_SIZE), Color.TRANSPARENT)
	img_fade_mask.fill_rect(Rect2(_position, ERASER_SIZE), Color.BLACK)


func _mod_erase_at(_position: Vector2) -> void:
	img.fill_rect(Rect2(_position, ERASER_SIZE_MOD), Color.TRANSPARENT)
	img_fade_mask.fill_rect(Rect2(_position, ERASER_SIZE_MOD), Color.BLACK)


func clear() -> void:
	if FileAccess.file_exists(DRAWING_CACHE_FILE):
		OS.move_to_trash(ProjectSettings.globalize_path(DRAWING_CACHE_FILE))
	if FileAccess.file_exists(DRAWING_FADE_CACHE_FILE):
		OS.move_to_trash(ProjectSettings.globalize_path(DRAWING_FADE_CACHE_FILE))
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
	else:
		if Time.get_ticks_msec() - last_cache > 90 * 1000:
			cache_drawing()


func _on_timer_fade_timeout() -> void:
	fade_queued = true
	thread_needed = true


func _on_capture_scene_save_drawing() -> void:
	cache_drawing()
	
	var drawings_dir: DirAccess
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SAVED_DRAWINGS_DIR)):
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SAVED_DRAWINGS_DIR))
	drawings_dir = DirAccess.open(SAVED_DRAWINGS_DIR)
	var num_files: int = drawings_dir.get_files().size()
	var filename: String = "drawing%s.png" % num_files
	var filename_jpg: String = "drawing%s.jpg" % num_files
	
	var bg: Image = DisplayServer.screen_get_image(0)
	if bg.get_size() != img.get_size():
		bg.resize(img.get_size().x, img.get_size().y)
	if bg.get_format() != img.get_format():
		bg.convert(img.get_format())
	bg.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)
	#bg.save_png(SAVED_DRAWINGS_DIR.path_join(filename))
	bg.save_jpg(SAVED_DRAWINGS_DIR.path_join(filename_jpg))
	
	#img.save_png(SAVED_DRAWINGS_DIR.path_join(filename))
