extends Window
class_name ViewerWindow


signal leaving(my_id: String)


const MARKER_DISPLAY_NAME_LABELSETTINGS = preload("res://Mods/StreamWorld/helper/marker_display_name_labelsettings.tres")
const LIFETIME: float = 60.0
const FADE_START: float = 45.0
const ICON = preload("res://icon.svg")
const VIEWERMARKER = preload("res://Mods/StreamWorld/greenheat/viewermarker.png")
const POLY: PackedVector2Array = [
								Vector2(3.0, 73.0), Vector2(174.0, 216.0), Vector2(186.0, 216.0),
								Vector2(209.0, 234.0), Vector2(217.0, 231.0), Vector2(234.0, 253.0),
								Vector2(253.0, 255.0), Vector2(258.0, 244.0), Vector2(247.0, 218.0),
								Vector2(250.0, 211.0), Vector2(231.0, 179.0), Vector2(232.0, 167.0),
								Vector2(86.0, 2.0), Vector2(62.0, 3.0), Vector2(1.0, 49.0)
								]


var display_name: String
var id: String
var pos: Vector2
var internal_pos: Vector2
var timer: Timer
var tex_rect: TextureRect
var clr: Color
var hover := true


func _ready() -> void:
	transparent = true
	unresizable = true
	borderless = true
	always_on_top = true
	unfocusable = true
	size = Vector2i(256, 256)
	mouse_passthrough_polygon = POLY
	var new_tex_rect := TextureRect.new()
	new_tex_rect.texture = VIEWERMARKER
	#new_tex_rect.scale = Vector2(2.0, 2.0)
	new_tex_rect.modulate = clr
	new_tex_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_child(new_tex_rect)
	tex_rect = new_tex_rect
	
	var new_label := Label.new()
	new_label.text = display_name
	new_label.label_settings = MARKER_DISPLAY_NAME_LABELSETTINGS
	new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(new_label)
	new_label.rotation = PI/4.0
	new_label.position = (size / 4.0) + Vector2(24.0, -16.0)
	
	var new_timer := Timer.new()
	new_timer.wait_time = LIFETIME
	new_timer.autostart = true
	new_timer.one_shot = true
	add_child(new_timer)
	timer = new_timer
	timer.timeout.connect(_on_timer_timeout)


func _process(delta: float) -> void:
	var l: float = 0.6
	if hover:
		l = 0.1
	internal_pos = internal_pos.lerp(pos, l)
	position = internal_pos - Vector2(size)
	
	var a: float = clampf(remap(timer.time_left, 0.0, timer.wait_time - FADE_START, 0.0, 1.0), 0.0, 1.0)
	tex_rect.modulate = Color(clr.r, clr.g, clr.b, a)


func update() -> void:
	timer.start()


func _on_timer_timeout() -> void:
	leaving.emit(id)
	queue_free()
