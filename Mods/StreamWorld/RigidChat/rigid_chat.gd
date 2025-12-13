extends RigidBody3D
class_name RigidChat


const CHAT_WIDTH: float = 0.7


var text: String
var max_width: float
var hang_from: PhysicsBody3D

var joint: Generic6DOFJoint3D


func _ready() -> void:
	mass = 0.01
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	#set_collision_layer_value(8, true)
	set_collision_mask_value(8, true)
	
	var new_meshinstance := MeshInstance3D.new()
	var new_textmesh := TextMesh.new()
	new_textmesh.text = text
	new_textmesh.pixel_size = 0.005
	new_textmesh.width = CHAT_WIDTH / new_textmesh.pixel_size
	new_textmesh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	new_textmesh.depth = 0.007
	new_meshinstance.mesh = new_textmesh
	add_child(new_meshinstance)
	
	var collider := CollisionShape3D.new()
	var new_box_shape := BoxShape3D.new()
	new_box_shape.size = Vector3(CHAT_WIDTH, 0.1, 0.1)
	collider.shape = new_box_shape
	
	add_child(collider)
	
	var new_joint := Generic6DOFJoint3D.new()
	new_joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
	new_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.1)
	new_joint.node_a = get_path()
	new_joint.node_b = hang_from.get_path()
	
	add_child(new_joint)
	joint = new_joint


func rejoin(new_body: PhysicsBody3D) -> void:
	joint.node_b = new_body.get_path()
	#joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -1.0)
	#joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.2)
