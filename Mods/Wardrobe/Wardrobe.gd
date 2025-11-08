extends Mod_Base
class_name Wardrobe


const SENS: float = 0.003


var rot_h: float = 0.0
var rot_v: float = 0.0:
	set(value):
		rot_v = clampf(value, -PI/2.1, PI/2.1)
var dragging_camera := false
var cam_dist: float = 3.0:
	set(value):
		cam_dist = clampf(value, 0.2, 4.0)
var cam_height: float = 1.0:
	set(value):
		cam_height = clampf(value, 0.0, 2.0)

var model: Node3D


@onready var ux: Control = $Window/UX
@onready var cam_h: Node3D = $Window/UX/TextureRect/SubViewport/WardrobeWorld/CamH
@onready var cam_v: Node3D = $Window/UX/TextureRect/SubViewport/WardrobeWorld/CamH/CamV
@onready var camera_3d: Camera3D = $Window/UX/TextureRect/SubViewport/WardrobeWorld/CamH/CamV/Camera3D
@onready var wardrobe_world: Node3D = $Window/UX/TextureRect/SubViewport/WardrobeWorld
@onready var sub_viewport: SubViewport = $Window/UX/TextureRect/SubViewport
@onready var cursor: MeshInstance3D = $Window/UX/TextureRect/SubViewport/WardrobeWorld/Cursor


func _ready() -> void:
	model = get_model().duplicate()
	wardrobe_world.add_child(model)
	
	var skel = get_skel(model)
	var avatar_collider = skel.find_child("AvatarCollider", true, false)
	if avatar_collider:
		avatar_collider.queue_free()
	skel.reset_bone_poses()
	
	var child_array: Array[Node] = get_children_recursive(skel)
	
	for child in child_array:
		if child.is_class("MeshInstance3D"):
			var mi: MeshInstance3D = child
			if mi.mesh:
				mi.create_trimesh_collision()


func _on_ux_gui_input(event: InputEvent) -> void:
	var rotation_scale = 0.5
	var pan_scale = 0.001
	var zoom_scale = 0.2
	var height_scale = 0.1

	if event is InputEventMouseButton:
		# FIXME: OffKai Steam-Deck hack!
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging_camera = true
			else:
				dragging_camera = false
		
		if event.pressed:
			if Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_ENTER):
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					cam_height += height_scale
				if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					cam_height -= height_scale
			else:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					cam_dist -= zoom_scale
				if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					cam_dist += zoom_scale
	
	if event is InputEventMouseMotion and dragging_camera:
		rot_h -= event.screen_relative.x * SENS
		rot_v -= event.screen_relative.y * SENS


func _process(delta: float) -> void:
	cam_h.rotation.y = rot_h
	cam_v.rotation.x = rot_v
	camera_3d.position.z = cam_dist
	cam_h.position.y = cam_height
	
	var cast_result: Dictionary = cast()
	
	if cast_result:
		cursor.position = cast_result["position"]


func get_skel(model: Node3D) -> Skeleton3D:
	var skeleton = model.find_child("GeneralSkeleton", true, false)
	if skeleton:
		return skeleton

	skeleton = model.find_child("Skeleton3D", true, false)
	if skeleton:
		return skeleton
	
	return null


func generate_colliders(skel: Skeleton3D) -> void:
	pass


func get_children_recursive(node: Node3D) -> Array[Node]:
	var child_array: Array[Node] = []
	for child in node.get_children():
		if child.get_child_count():
			child_array.append_array(get_children_recursive(child))
		else:
			child_array.append(child)
	return child_array


func cast(collision_mask: int = 1) -> Dictionary:
	var space_state = camera_3d.get_world_3d().direct_space_state
	var mousepos = ux.get_global_mouse_position()
	var origin = camera_3d.project_ray_origin(mousepos)
	var end = origin + camera_3d.project_ray_normal(mousepos) * 50.0
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	#query.collision_mask = collision_mask
	#query.collide_with_areas = hit_areas
	#if exclude_nodes:
		#query.exclude = exclude_nodes
	var result = space_state.intersect_ray(query)
	return result
	#if result:
		#emit_signal("RayHit", result, collision_mask)
