extends Node3D


@onready var x_11_display_capture: X11DisplayCapture = $X11DisplayCapture
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D


var capture := true


func _ready() -> void:
	x_11_display_capture.texture_changed.connect(_texture_changed)
	x_11_display_capture.set_index(0)


func _texture_changed(texture: Texture2D) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance_3d.material_override = mat


func _process(delta: float) -> void:
	# 30fps hack
	if capture:
		x_11_display_capture.process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		x_11_display_capture.process_mode = Node.PROCESS_MODE_DISABLED
	capture = !capture
