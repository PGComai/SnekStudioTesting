extends Resource
class_name Brush


const DK_64_DONKEY_KONG_ICON_112 = preload("uid://crlir0kcgjsnq")
const DK_64_DONKEY_KONG_ICON_112_MASK = preload("uid://cpmr8e7wr8jqm")
const DK_64_DONKEY_KONG_ICON_32 = preload("uid://ca7ly7axwf2w4")
const DK_64_DONKEY_KONG_ICON_32_MASK = preload("uid://baasq5g0i0tov")


enum BrushType{ROUND, DK, CUSTOM, CUSTOM_TILE}


var type: BrushType = BrushType.ROUND
var custom_image: Image
var custom_mask: Image
var custom_mask_2: Image
var custom_secondary_mask: Image
var custom_tile_image: Image
var custom_tile_mask: Image
var brush_image: Image
var brush_mask: Image
var size: int = 12
var clr: Color = Color.WHITE
var ease_curve: float = 0.2
var splatter: float = 0.0
var sparse: int = 0
var tiling_offset := Vector2i.ZERO


func needs_speedup() -> bool:
	return type == BrushType.DK or size > 50


func make_brush() -> void:
	if type == BrushType.CUSTOM:
		size = 32
	brush_image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	brush_mask = Image.create_empty(size, size, false, Image.FORMAT_LA8)
	var brush_size: Vector2i = brush_image.get_size()
	var brush_center: Vector2 = Vector2(float(brush_size.x - 1) / 2.0, float(brush_size.y - 1) / 2.0)
	if type == BrushType.ROUND:
		for x in size:
			for y in size:
				var pt := Vector2i(x, y)
				var pt_c: Vector2 = Vector2(pt) - brush_center
				var strength: float = 1.0 - clampf(remap(pt_c.length(), 0.0, brush_size.x / 2.0, 0.0, 1.0), 0.0, 1.0)
				strength = ease(strength, ease_curve)
				var pixel_color: Color = clr
				pixel_color.a = strength
				brush_image.set_pixelv(pt, pixel_color)
				brush_mask.set_pixelv(pt, Color(1.0, 1.0, 1.0, strength))
	elif type == BrushType.DK:
		brush_image = DK_64_DONKEY_KONG_ICON_32
		brush_mask = DK_64_DONKEY_KONG_ICON_32_MASK
		brush_image.convert(Image.FORMAT_RGBA8)
		brush_mask.convert(Image.FORMAT_LA8)
	elif type == BrushType.CUSTOM:
		#size = custom_image.get_size().x
		brush_image = custom_image
		brush_mask = custom_mask
		brush_image.convert(Image.FORMAT_RGBA8)
		brush_mask.convert(Image.FORMAT_LA8)
		if custom_mask_2:
			make_secondary_mask()
	elif type == BrushType.CUSTOM_TILE:
		make_tile()
		render_offset()
	
	if type != BrushType.ROUND:
		render_color_or_colorless()


func make_secondary_mask() -> void:
	if not custom_secondary_mask:
		custom_secondary_mask = Image.create_empty(size, size, false, Image.FORMAT_LA8)
	custom_secondary_mask.fill(Color(1.0, 1.0, 1.0, 0.0))
	custom_secondary_mask.blend_rect_mask(brush_mask, custom_mask_2, Rect2i(0, 0, size, size), Vector2i.ZERO)


func make_tile() -> void:
	size = custom_image.get_size().x
	var full_quarter: int = size / 2
	var full_half: int = size
	var full_3q: int = full_quarter * 3
	custom_tile_image = Image.create_empty(size * 2, size * 2, false, Image.FORMAT_RGBA8)
	custom_tile_mask = Image.create_empty(size * 2, size * 2, false, Image.FORMAT_LA8)
	custom_image.convert(Image.FORMAT_RGBA8)
	custom_mask.convert(Image.FORMAT_LA8)
	custom_tile_image.blit_rect(custom_image, Rect2i(0, 0, size, size), Vector2i(full_quarter, full_quarter))
	
	custom_tile_image.blit_rect(custom_image, Rect2i(0, 0, size/2, size), Vector2i(full_3q, full_quarter))
	custom_tile_image.blit_rect(custom_image, Rect2i(size/2, 0, size/2, size), Vector2i(0, full_quarter))
	custom_tile_image.blit_rect(custom_image, Rect2i(0, 0, size, size/2), Vector2i(full_quarter, full_3q))
	custom_tile_image.blit_rect(custom_image, Rect2i(0, size/2, size, size/2), Vector2i(full_quarter, 0))
	
	custom_tile_image.blit_rect(custom_image, Rect2i(0, 0, size/2, size/2), Vector2i(full_3q, full_3q))
	custom_tile_image.blit_rect(custom_image, Rect2i(size/2, 0, size/2, size/2), Vector2i(0, full_3q))
	custom_tile_image.blit_rect(custom_image, Rect2i(0, size/2, size/2, size/2), Vector2i(full_3q, 0))
	custom_tile_image.blit_rect(custom_image, Rect2i(size/2, size/2, size/2, size/2), Vector2i(0, 0))
	
	
	custom_tile_mask.blit_rect(custom_mask, Rect2i(0, 0, size, size), Vector2i(full_quarter, full_quarter))
	
	custom_tile_mask.blit_rect(custom_mask, Rect2i(0, 0, size/2, size), Vector2i(full_3q, full_quarter))
	custom_tile_mask.blit_rect(custom_mask, Rect2i(size/2, 0, size/2, size), Vector2i(0, full_quarter))
	custom_tile_mask.blit_rect(custom_mask, Rect2i(0, 0, size, size/2), Vector2i(full_quarter, full_3q))
	custom_tile_mask.blit_rect(custom_mask, Rect2i(0, size/2, size, size/2), Vector2i(full_quarter, 0))
	
	custom_tile_mask.blit_rect(custom_mask, Rect2i(0, 0, size/2, size/2), Vector2i(full_3q, full_3q))
	custom_tile_mask.blit_rect(custom_mask, Rect2i(size/2, 0, size/2, size/2), Vector2i(0, full_3q))
	custom_tile_mask.blit_rect(custom_mask, Rect2i(0, size/2, size/2, size/2), Vector2i(full_3q, 0))
	custom_tile_mask.blit_rect(custom_mask, Rect2i(size/2, size/2, size/2, size/2), Vector2i(0, 0))


func clear_custom_mask() -> void:
	custom_mask_2 = null
	custom_secondary_mask = null


func render_color_or_colorless() -> void:
	if clr.is_equal_approx(Color.WHITE):
		render_colorless()
	else:
		render_color()


func render_colorless() -> void:
	print("render brush colorless")
	if type == BrushType.CUSTOM:
		brush_image = custom_image
		brush_image.convert(Image.FORMAT_RGBA8)
	elif type == BrushType.CUSTOM_TILE:
		make_tile()


func render_color() -> void:
	if type == BrushType.ROUND:
		make_brush()
	elif type == BrushType.CUSTOM_TILE:
		var clr_img := Image.create(size * 2, size * 2, false, Image.FORMAT_RGBA8)
		clr_img.fill(clr)
		custom_tile_image.blend_rect_mask(clr_img, custom_tile_mask, Rect2i(0, 0, size * 2, size * 2), Vector2i.ZERO)
	elif type == BrushType.CUSTOM:
		var colorized_image: Image = custom_image.duplicate()
		for x: int in size:
			for y: int in size:
				var p: Color = colorized_image.get_pixel(x, y)
				var a: float = p.a
				p.a = 1.0
				var blend_clr: Color = clr
				blend_clr.a = 0.5
				var new_clr: Color = p.blend(blend_clr)
				new_clr.a = a
				colorized_image.set_pixel(x, y, new_clr)
		brush_image = colorized_image
		#var clr_img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		#var clr_img_masked := Image.create(size, size, false, Image.FORMAT_RGBA8)
		#var color_overlay := Color(clr.r, clr.b, clr.g, 0.5)
		#clr_img.fill(color_overlay)
		#clr_img_masked.fill(Color(1.0, 1.0, 1.0, 0.0))
		#var desired_mask: Image
		#if custom_mask_2:
			#desired_mask = custom_mask_2
		#else:
			#desired_mask = custom_mask
		#clr_img_masked.blend_rect_mask(clr_img, desired_mask, Rect2i(0, 0, size, size), Vector2i.ZERO)
		#brush_image = custom_image.duplicate()
		#brush_image.blend_rect_mask(clr_img_masked, desired_mask, Rect2i(0, 0, size, size), Vector2i.ZERO)


func render_offset() -> void:
	var full_quarter: int = size / 2
	var full_half: int = size
	var full_3q: int = full_quarter * 3
	var offset_rect := Rect2i(tiling_offset.x % size, tiling_offset.y % size, size, size)
	brush_image = custom_tile_image.get_region(offset_rect)
	brush_mask = custom_tile_mask.get_region(offset_rect)
	if custom_mask_2:
		make_secondary_mask()
