extends Area3D
class_name ChatBubble


const RADIUS: float = 0.1


var color: Color


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
