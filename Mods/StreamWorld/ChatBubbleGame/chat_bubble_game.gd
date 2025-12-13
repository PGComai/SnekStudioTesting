extends Node3D
class_name ChatBubbleGame


const LAUNCHER_ANGLE: float = PI/3.0
const CAST_DIST: float = 5.0
const TOP: float = 1.08
const BUBBLE_Z: float = 0.1
const BUBBLE_SPEED: float = 0.1


@export_flags_3d_physics var shape_mask


var angle: float = 0.0
var angling := true
var can_fire := true
var bubble_positions: Array[Vector3] = []
var current_bubble: ChatBubble


@onready var bubble_launcher: Node3D = $BubbleLauncher


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if angling:
		angle += delta
		bubble_launcher.rotation.z = sin(angle) * LAUNCHER_ANGLE
	if current_bubble:
		current_bubble.position = current_bubble.position.move_toward(bubble_positions[0], BUBBLE_SPEED)
		if current_bubble.position.is_equal_approx(bubble_positions[0]):
			current_bubble.position = bubble_positions[0]
			bubble_positions.remove_at(0)
			if bubble_positions.size() == 0:
				current_bubble = null
				can_fire = true
				bubble_positions = []


func fire_bubble() -> void:
	var new_bubble := ChatBubble.new()
	new_bubble.color = Color.BLUE
	
	var bouncing := true
	
	var cast_result: Dictionary = shapecast(
								bubble_launcher.global_position,
								bubble_launcher.global_position + (bubble_launcher.global_basis.y * CAST_DIST))
	var bubble_pos: Vector3 = cast_result.safe_position
	var local_bubble_pos: Vector3 = to_local(bubble_pos)
	bubble_positions.append(local_bubble_pos)
	var collider: Object = instance_from_id(cast_result.collider_id)
	var pos2d: Vector2 = Vector2(local_bubble_pos.x, local_bubble_pos.y)
	var bubble_row: int = get_hex_grid_row(pos2d)
	var cast_dir: Vector3 = cast_result.cast_direction
	
	if collider.is_in_group("chat_bubble") or bubble_row == 0:
		bouncing = false
		#bubble_pos = cast_result.safe_position
	
	while bouncing:
		print("bounce")
		var new_heading: Vector3 = cast_dir.bounce(cast_result.normal).normalized()
		cast_result = shapecast(
							cast_result.safe_position,
							cast_result.safe_position + (new_heading * CAST_DIST))
		collider = instance_from_id(cast_result.collider_id)
		bubble_pos = cast_result.safe_position
		local_bubble_pos = to_local(bubble_pos)
		bubble_positions.append(local_bubble_pos)
		cast_dir = cast_result.cast_direction
		
		#shape_cast_3d.look_at_from_position(next_safe_pos, next_safe_pos + Vector3.FORWARD, next_norm)
		#shape_cast_3d.force_update_transform()
		#shape_cast_3d.force_shapecast_update()
		
		#collider = shape_cast_3d.get_collider(0)
		pos2d = Vector2(local_bubble_pos.x, local_bubble_pos.y)
		bubble_row = get_hex_grid_row(pos2d)
		if collider.is_in_group("chat_bubble") or bubble_row == 0:
			bouncing = false
	
	pos2d = Vector2(local_bubble_pos.x, local_bubble_pos.y)
	bubble_row = get_hex_grid_row(pos2d)
	var bubble_x: float = get_hex_grid_x(pos2d, bubble_row)
	var bubble_y: float = TOP - (ChatBubble.RADIUS + (sin(PI/3.0) * ChatBubble.RADIUS * 2.0 * float(bubble_row)))
	
	add_child(new_bubble)
	current_bubble = new_bubble
	current_bubble.position = bubble_launcher.position
	can_fire = false


func shapecast(from: Vector3, to: Vector3) -> Dictionary:
	var state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var cast_shape := SphereShape3D.new()
	cast_shape.radius = ChatBubble.RADIUS
	var query := PhysicsShapeQueryParameters3D.new()
	query.collision_mask = shape_mask
	query.collide_with_areas = true
	query.shape = cast_shape
	query.transform = Transform3D(Basis.IDENTITY, from)
	query.motion = from.direction_to(to) * CAST_DIST
	var motion_cast: PackedFloat32Array = state.cast_motion(query)
	var safe_dist: float = CAST_DIST * motion_cast[0]
	var unsafe_dist: float = CAST_DIST * motion_cast[1]
	var next_safe_pos: Vector3 = from + (from.direction_to(to) * safe_dist)
	var next_unsafe_pos: Vector3 = from + (from.direction_to(to) * unsafe_dist)
	
	if unsafe_dist == 1.0 and safe_dist == 1.0:
		pass
	else:
		query.transform.origin = next_unsafe_pos
		var rest_info: Dictionary = state.get_rest_info(query)
		rest_info["safe_position"] = next_safe_pos
		rest_info["cast_direction"] = from.direction_to(to)
		return rest_info
	
	return {}


func get_hex_grid_row(v: Vector2) -> int:
	var row: int
	
	var height: float = v.y
	var row_0: float = TOP - ChatBubble.RADIUS
	var diff: float = row_0 - height
	var snap_factor: float = sin(PI/3.0) * ChatBubble.RADIUS * 2.0
	var diff_snap: float = snappedf(diff, snap_factor)
	
	
	return roundi(diff_snap / snap_factor)


func get_hex_grid_x(v: Vector2, row: int) -> float:
	var x: float
	
	var row_float: float = float(row)
	var even: bool = row % 2 == 0
	var snap_factor: float = cos(PI/3.0) * ChatBubble.RADIUS * 2.0
	
	if even:
		x = snappedf(v.x, ChatBubble.RADIUS * 2.0)
	else:
		x = snappedf(v.x, ChatBubble.RADIUS * 2.0)
	
	return x
