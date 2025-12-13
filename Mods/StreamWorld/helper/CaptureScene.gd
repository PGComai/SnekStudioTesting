extends Node3D
class_name CaptureScene


@export var screen_materials: Dictionary[StringName, Material]


var capture := true
var capture_material: StandardMaterial3D


@onready var x_11_display_capture: X11DisplayCapture = $X11DisplayCapture
@onready var mesh_instance_3d: MeshInstance3D = $WholeMonitor/MeshInstance3D
@onready var mouse: AnimatableBody3D = $WholeMonitor/MeshInstance3D/Mouse
@onready var cursor: RigidBody3D = $Cursor
@onready var chat_bubble_game: ChatBubbleGame = $WholeMonitor/ChatBubbleGame


func _ready() -> void:
	x_11_display_capture.texture_changed.connect(_texture_changed)
	x_11_display_capture.set_index(0)


func _texture_changed(texture: Texture2D) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance_3d.material_overlay = mat
	capture_material = mat


func _process(delta: float) -> void:
	# 30fps hack
	if capture:
		x_11_display_capture.process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		x_11_display_capture.process_mode = Node.PROCESS_MODE_DISABLED
	capture = !capture
	
	var mousepos: Vector2 = Vector2(DisplayServer.mouse_get_position() - Vector2i(1080, 0))
	
	var mouse_pos_scaled: Vector2 = mousepos / 1000.0
	
	mouse.position = Vector3(
							mouse_pos_scaled.x - (3.84 / 2.0),
							-(mouse_pos_scaled.y - (2.16 / 2.0)),
							0.0)


func launch_bubble() -> void:
	chat_bubble_game.fire_bubble()
