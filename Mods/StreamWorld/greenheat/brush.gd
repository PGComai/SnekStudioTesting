extends Resource
class_name Brush


const DK_64_DONKEY_KONG_ICON_112 = preload("uid://crlir0kcgjsnq")
const DK_64_DONKEY_KONG_ICON_112_MASK = preload("uid://cpmr8e7wr8jqm")
const DK_64_DONKEY_KONG_ICON_32 = preload("uid://ca7ly7axwf2w4")
const DK_64_DONKEY_KONG_ICON_32_MASK = preload("uid://baasq5g0i0tov")


enum BrushType{ROUND, DK}


var type: BrushType = BrushType.ROUND
var brush_image: Image
var brush_mask: Image
var size: int = 12
var clr: Color:
	set(value):
		clr = value
		make_brush()
var ease_curve: float = 0.2
var splatter: float = 0.0
var sparse: int = 0


func needs_speedup() -> bool:
	return type == BrushType.DK or size > 50


func make_brush() -> void:
	if type == BrushType.DK:
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
