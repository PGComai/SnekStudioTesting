extends Sprite3D
class_name BrushPreview


@export var img: Image
@export var mask: Image
@export var mask2: Image
@export_flags_3d_physics var hit_layer: int
@export var tiled := false


var hovered := false
var highlighted: float = 0.0:
	set(value):
		highlighted = maxf(value, 0.0)
var highlight: Sprite3D


func _enter_tree() -> void:
	if img:
		texture = ImageTexture.create_from_image(img)
	var area := Area3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.2, 0.1, 0.2)
	collider.shape = shape
	area.collision_layer = hit_layer
	area.collision_mask = 0
	
	add_child(area)
	area.add_child(collider)
	if img and mask:
		pixel_size = 0.005 * (32.0 / float(img.get_size().x))
		area.set_meta("img", img)
		area.set_meta("mask", mask)
		highlight = Sprite3D.new()
		highlight.texture = texture
		highlight.modulate = Color.BLACK
		highlight.pixel_size = pixel_size * 1.2
		add_child(highlight)
		highlight.position.z -= 0.0005
		texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		highlight.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		highlight.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		highlight.alpha_scissor_threshold = 0.01
		highlight.transparency = 1.0


func _process(delta: float) -> void:
	if highlighted:
		highlighted -= delta
		if highlight:
			highlight.transparency = 1.0 - highlighted
