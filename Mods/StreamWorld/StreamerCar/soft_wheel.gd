@tool
extends RigidBody3D
class_name SoftWheel


@export_tool_button("Generate") var _generate = generate
@export var radius: float = 0.3
@export var res: int = 8
@export var connect_to: PhysicsBody3D
@export_flags_3d_physics var tire_collision_layer: int
@export_flags_3d_physics var tire_collision_mask: int


var joint: HingeJoint3D


func _ready() -> void:
	if not Engine.is_editor_hint():
		generate(false)
		if connect_to:
			joint.node_a = get_path()
			joint.node_b = connect_to.get_path()


func generate(editor := true) -> void:
	for child in get_children():
		child.queue_free()
	
	var my_collider := CollisionShape3D.new()
	var my_sphereshape := SphereShape3D.new()
	my_sphereshape.radius = radius / 2.0
	my_collider.shape = my_sphereshape
	add_child(my_collider)
	
	joint = HingeJoint3D.new()
	add_child(joint)
	joint.rotation.y = PI/2.0
	
	var balls: Array[RigidBody3D] = []
	
	for i in res:
		var theta: float = (float(i) / float(res)) * TAU
		var pos: Vector3 = Vector3(
								0.0,
								cos(theta) * radius,
								sin(theta) * radius
								)
		
		var new_collider := CollisionShape3D.new()
		var sphereshape := SphereShape3D.new()
		sphereshape.radius = radius / 2.0
		new_collider.shape = sphereshape
		add_child(new_collider)
		new_collider.position = pos
		
		var new_mesh := MeshInstance3D.new()
		var spheremesh := SphereMesh.new()
		spheremesh.radius = radius / 2.0
		spheremesh.height = radius
		new_mesh.mesh = spheremesh
		new_collider.add_child(new_mesh)
		
		#var new_ball := RigidBody3D.new()
		#var new_mesh := MeshInstance3D.new()
		#var new_collider := CollisionShape3D.new()
		#var new_joint := Generic6DOFJoint3D.new()
		#
		#var spheremesh := SphereMesh.new()
		#spheremesh.radius = radius / 2.0
		#spheremesh.height = radius
		#
		#var sphereshape := SphereShape3D.new()
		#sphereshape.radius = radius / 2.0
		#
		#new_mesh.mesh = spheremesh
		#new_collider.shape = sphereshape
		#
		#add_child(new_ball)
		#new_ball.add_child(new_collider)
		#new_ball.add_child(new_mesh)
		#new_ball.add_child(new_joint)
		#
		#new_ball.position = pos
		#
		#new_joint.node_a = new_ball.get_path()
		#new_joint.node_b = get_path()
		#
		#if not editor:
			#new_ball.collision_layer = tire_collision_layer
			#new_ball.collision_mask = tire_collision_mask
			##new_ball.top_level = true
		#balls.append(new_ball)
	
	#for i: int in balls.size():
		#var next_i: int = wrapi(i + 1, 0, balls.size())
		#var ball: RigidBody3D = balls[i]
		#var next_ball: RigidBody3D = balls[next_i]
		#
		#var new_joint := Generic6DOFJoint3D.new()
		#ball.add_child(new_joint)
		#new_joint.position = ball.position.lerp(next_ball.position, 0.5)
		#new_joint.node_a = ball.get_path()
		#new_joint.node_b = next_ball.get_path()
