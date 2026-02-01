extends Node3D
class_name CaptureScene


const MAX_VIEWER_WINDOWS: int = 20


signal screen_interacted(packet: Dictionary, virtual_screen_pos: Vector2)


@export var screen_materials: Dictionary[StringName, Material]
@export var bubble_game := false
@export var cast_camera: Camera3D
@export var exclude_nodes: Array[Node]
@export_flags_3d_physics var cast_layer: int


var capture := true
var capture_material: StandardMaterial3D
var brb := false:
	set(value):
		if brb != value:
			brb = value
			if chat_bubble_game and bubble_game:
				chat_bubble_game.enabled = value
				chat_bubble_game.visible = value
var text_3d: String = "BRB":
	set(value):
		if text_3d != value:
			text_3d = value
			if text:
				text.mesh.text = text_3d
var cursor_pos_rolling: Array[Vector2] = []
var viewer_cursors: Dictionary[String, ViewerCursor]
var viewer_windows: Dictionary[String, ViewerWindow]
var colors: Dictionary[String, Color] = {}


@onready var eraser_cursor: Node3D = $WholeMonitor/EraserCursor
@onready var x_11_display_capture: X11DisplayCapture = $X11DisplayCapture
@onready var mesh_instance_3d: MeshInstance3D = $WholeMonitor/MeshInstance3D
@onready var mouse: AnimatableBody3D = $WholeMonitor/MeshInstance3D/Mouse
@onready var cursor: RigidBody3D = $Cursor
@onready var chat_bubble_game: ChatBubbleGame = $WholeMonitor/ChatBubbleGame
@onready var whole_monitor: Node3D = $WholeMonitor
@onready var text: MeshInstance3D = $WholeMonitor/Text


func _ready() -> void:
	chat_bubble_game.visible = false
	x_11_display_capture.texture_changed.connect(_texture_changed)
	x_11_display_capture.set_index(0)


func _texture_changed(texture: Texture2D) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.emission_texture = texture
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.2, 0.2, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance_3d.material_overlay = mat
	capture_material = mat


func mouse_to_world(mouse_pos: Vector2i) -> Vector3:
	var mousepos: Vector2 = Vector2(mouse_pos - Vector2i(1080, 0))
	var mouse_pos_scaled: Vector2 = mousepos / 1000.0
	return Vector3(
							mouse_pos_scaled.x - (3.84 / 2.0),
							-(mouse_pos_scaled.y - (2.16 / 2.0)),
							0.0)


func _process(delta: float) -> void:
	# 30fps hack
	if capture:
		x_11_display_capture.process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		x_11_display_capture.process_mode = Node.PROCESS_MODE_DISABLED
	capture = !capture
	
	#prints("DisplayServer mouse pos: ", DisplayServer.mouse_get_position())
	mouse.position = mouse_to_world(DisplayServer.mouse_get_position())
	
	#cursor_pos_rolling.append(Vector2(mouse.position.x, mouse.position.y))
	#if cursor_pos_rolling.size() > 30:
		#cursor_pos_rolling.remove_at(0)
	#
	#var cursor_pos_smooth := Vector2.ZERO
	#
	#for pos: Vector2 in cursor_pos_rolling:
		#cursor_pos_smooth += pos
	#
	#cursor_pos_smooth /= float(cursor_pos_rolling.size())
	#
	#print(cursor_pos_smooth)


func _physics_process(delta: float) -> void:
	if brb:
		whole_monitor.rotation.y = minf(whole_monitor.rotation.y + delta, PI)
	else:
		whole_monitor.rotation.y = maxf(whole_monitor.rotation.y - delta, 0.0)


func launch_bubble() -> void:
	if chat_bubble_game.enabled:
		chat_bubble_game.fire_bubble()


func _on_check_button_brb_toggled(toggled_on: bool) -> void:
	brb = toggled_on


func _on_line_edit_text_3d_text_changed(new_text: String) -> void:
	text_3d = new_text


func handle_common(packet: Dictionary) -> void:
	if not colors.has(packet.id):
		colors[packet.id] = Color(
							randf_range(0.3, 0.9),
							randf_range(0.3, 0.9),
							randf_range(0.3, 0.9),
							1.0)


func handle_gh_packet(packet: Dictionary) -> void:
	handle_common(packet)
	var id: String = packet["id"]
	var pos := Vector2(packet["x"], packet["y"]) * Vector2(1920.0, 1080.0)
	var pos_screen := Vector2(packet["x"], packet["y"]) * Vector2(3840.0, 2160.0)
	var cast_result: Dictionary = cast(pos)
	if cast_result.has("position"):
		var pos3d: Vector3 = whole_monitor.to_local(cast_result["position"])
		# -3.84 / 2.0 < pos3d.x < 3.84 / 2.0
		var virtual_x: float = remap(pos3d.x, -3.84 / 2.0, 3.84 / 2.0, 0.0, 3840.0)
		var virtual_y: float = -remap(pos3d.y, -2.16 / 2.0, 2.16 / 2.0, -2160.0, 0.0)
		var pos_virtual_screen := Vector2(virtual_x + 1080.0, virtual_y)
		screen_interacted.emit(packet, Vector2(virtual_x, virtual_y))
		var tick: int = Time.get_ticks_msec()
		if viewer_cursors.has(id):
			viewer_cursors[id].pos = pos3d
			viewer_cursors[id].last_input = tick
			
			viewer_windows[id].pos = pos_virtual_screen
			viewer_windows[id].hover = packet.type == "hover"
			viewer_windows[id].update()
		elif viewer_windows.size() < MAX_VIEWER_WINDOWS:
			var new_viewer_cursor := ViewerCursor.new()
			new_viewer_cursor.clr = colors[packet.id]
			new_viewer_cursor.pos = pos3d
			new_viewer_cursor.last_input = tick
			whole_monitor.add_child(new_viewer_cursor)
			viewer_cursors[id] = new_viewer_cursor
			
			var new_viewer_window := ViewerWindow.new()
			new_viewer_window.pos = pos_virtual_screen
			new_viewer_window.internal_pos = pos_virtual_screen
			new_viewer_window.id = id
			new_viewer_window.clr = colors[packet.id]
			new_viewer_window.leaving.connect(_on_viewer_window_leaving)
			add_child(new_viewer_window)
			viewer_windows[id] = new_viewer_window


func _on_viewer_window_leaving(window_id: String) -> void:
	if viewer_windows.has(window_id):
		viewer_windows.erase(window_id)
	if viewer_cursors.has(window_id):
		viewer_cursors[window_id].queue_free()
		viewer_cursors.erase(window_id)


func _on_green_heat_hover_received(packet: Dictionary) -> void:
	handle_gh_packet(packet)


func _on_green_heat_release_received(packet: Dictionary) -> void:
	handle_gh_packet(packet)


func _on_green_heat_drag_received(packet: Dictionary) -> void:
	handle_gh_packet(packet)


func _on_green_heat_click_received(packet: Dictionary) -> void:
	handle_gh_packet(packet)


func cast(mousepos: Vector2):
	var space_state = get_world_3d().direct_space_state
	# if inside subviewport: parent_control_node.get_global_mouse_position()
	var origin = cast_camera.project_ray_origin(mousepos)
	var end = origin + cast_camera.project_ray_normal(mousepos) * 1000.0
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = cast_layer
	#query.collide_with_areas = hit_areas
	if exclude_nodes:
		query.exclude = exclude_nodes
	return space_state.intersect_ray(query)


func _on_window_eraser_erasing(absolute_pos: Vector2i) -> void:
	eraser_cursor.position = mouse_to_world(absolute_pos + Vector2i(100.0, 50.0))
	eraser_cursor.visible = true
	cursor.visible = false


func _on_window_eraser_erasing_done() -> void:
	eraser_cursor.visible = false
	cursor.visible = true
