extends Area3D
class_name ChatBubble


const RADIUS: float = 0.1


var color: Color
var text: String = ""


func _ready() -> void:
	add_to_group("chat_bubble")
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	set_collision_layer_value(5, true)
	set_collision_mask_value(5, true)
	
	var new_collider := CollisionShape3D.new()
	var new_shape := SphereShape3D.new()
	
	new_shape.radius = RADIUS
	new_collider.shape = new_shape
	
	add_child(new_collider)
	
	var new_mesh := MeshInstance3D.new()
	var new_spheremesh := SphereMesh.new()
	var new_mat := StandardMaterial3D.new()
	
	new_mat.albedo_color = color
	
	new_spheremesh.radius = RADIUS
	new_spheremesh.height = RADIUS * 2.0
	
	new_mesh.mesh = new_spheremesh
	new_mesh.material_override = new_mat
	
	add_child(new_mesh)
	
	var new_text := MeshInstance3D.new()
	var new_textmesh := TextMesh.new()
	new_textmesh.text = text
	new_textmesh.depth = 0.001
	new_textmesh.font_size = 4
	
	new_text.mesh = new_textmesh
	var new_text_mat := StandardMaterial3D.new()
	new_text_mat.no_depth_test = true
	new_text_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	new_text_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	new_text.material_override = new_text_mat
	
	add_child(new_text)
