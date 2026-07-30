extends Node3D
class_name CaptureScene


const MAX_VIEWER_WINDOWS: int = 20


signal screen_interacted(packet: Dictionary, virtual_screen_pos: Vector2, eraser: bool)
signal user_released(id: String)
signal save_drawing


@export var testing_markers := false
@export var marker_palette_color_gradient: Gradient
@export var marker_palette_gray_gradient: Gradient
@export var donut_material: Material
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
var text_3d: String = "BRB":
	set(value):
		if text_3d != value:
			text_3d = value
			if text:
				text.mesh.text = text_3d
var cursor_speed_rolling: Array[float] = []
var marker_permissions: Array[String] = []
var erase_marker_permissions: Array[String] = []
var enabled_drawers: Array[String] = []
var viewer_cursors: Dictionary[String, ViewerCursor]
var viewer_windows: Dictionary[String, ViewerWindow]
var marker_display_names: Dictionary[String, String]
var colors: Dictionary[String, Color] = {}
var brushes: Dictionary[String, Brush] = {}
var last_mouse_pos := Vector2i.ZERO
var stupid_pipe: FileAccess
var pipe_pid: int
var viewer_color_donuts: Dictionary[String, ColorDonut]
var viewer_brush_donuts: Dictionary[String, ColorDonut]
var mod_markers_only := false
var mod_ids: Array[String] = []
# TODO: try to match marker color to chatter color


@onready var eraser_cursor: Node3D = $WholeMonitor/EraserCursor
@onready var x_11_display_capture: X11DisplayCapture = $X11DisplayCapture
@onready var mesh_instance_3d: MeshInstance3D = $WholeMonitor/MeshInstance3D
@onready var mouse: AnimatableBody3D = $WholeMonitor/MeshInstance3D/Mouse
@onready var cursor: RigidBody3D = $Cursor
@onready var whole_monitor: Node3D = $WholeMonitor
@onready var text: MeshInstance3D = $WholeMonitor/Text
@onready var timer_thicker_lines: Timer = $TimerThickerLines
@onready var window_paint: WindowPaint = $WindowPaint
@onready var marker_color_area: Area3D = $WholeMonitor/MarkerColors/MarkerColorArea
@onready var monitor_body: AnimatableBody3D = $WholeMonitor/MeshInstance3D/Monitor/MonitorBody
@onready var timer_mods_only_draw: Timer = $TimerModsOnlyDraw


func _ready() -> void:
	x_11_display_capture.texture_changed.connect(_texture_changed)
	x_11_display_capture.set_index(0)
	#var pipe := OS.execute_with_pipe("bash", ["-c", "cat /var/log/Xorg.0.log"], false)
	#stupid_pipe = pipe.stderr
	#pipe_pid = pipe.pid


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


func _on_check_button_brb_toggled(toggled_on: bool) -> void:
	brb = toggled_on


func _on_line_edit_text_3d_text_changed(new_text: String) -> void:
	text_3d = new_text


func _on_window_tools_marker_permissions_revoked(user_id: String, display_name: String) -> void:
	marker_permissions.erase(user_id)


func _on_game_world_erase_marker_permissions_requested(user_id: String, display_name: String) -> void:
	mod_ids.append(user_id)
	if not marker_display_names.has(user_id):
		marker_display_names[user_id] = display_name
	if not erase_marker_permissions.has(user_id):
		erase_marker_permissions.append(user_id)


func _on_game_world_marker_permissions_requested(user_id: String, display_name: String) -> void:
	if not marker_display_names.has(user_id):
		marker_display_names[user_id] = display_name
	if not marker_permissions.has(user_id):
		marker_permissions.append(user_id)
	if not brushes.has(user_id):
		var new_brush := Brush.new()
		brushes[user_id] = new_brush


func handle_common(packet: Dictionary) -> void:
	if not colors.has(packet.id):
		var clr := Color(
						randf_range(0.3, 0.9),
						randf_range(0.3, 0.9),
						randf_range(0.3, 0.9),
						1.0)
		colors[packet.id] = clr
		brushes[packet.id].clr = clr


func add_color_donut(id: String, pos: Vector3) -> void:
	var new_donut := ColorDonut.new()
	new_donut.mat = donut_material
	new_donut.pos = pos
	new_donut.id = id
	new_donut.bye.connect(_on_color_donut_bye)
	marker_color_area.add_child(new_donut)
	viewer_color_donuts[id] = new_donut


func add_brush_donut(id: String, pos: Vector3) -> void:
	var new_donut := ColorDonut.new()
	new_donut.mat = donut_material
	new_donut.pos = pos
	new_donut.id = id
	new_donut.bye.connect(_on_brush_donut_bye)
	%BrushStore.add_child(new_donut)
	viewer_brush_donuts[id] = new_donut


func _on_color_donut_bye(id: String) -> void:
	if viewer_color_donuts.has(id):
		viewer_color_donuts.erase(id)


func _on_brush_donut_bye(id: String) -> void:
	if viewer_brush_donuts.has(id):
		viewer_brush_donuts.erase(id)


func handle_gh_packet(packet: Dictionary) -> void:
	if not %TextureRect.visible:
		return
	var id: String = packet["id"]
	var is_mod: bool = mod_ids.has(id)
	var can_draw: bool = marker_permissions.has(id) or testing_markers
	var draw_enabled: bool = enabled_drawers.has(id) or testing_markers
	if mod_markers_only:
		can_draw = is_mod
	else:
		can_draw = can_draw and draw_enabled
	if can_draw:
		if not brushes.has(id):
			var new_brush := Brush.new()
			new_brush.size = 12
			#if testing_markers:
				#new_brush.type = Brush.BrushType.DK
			new_brush.make_brush()
			brushes[id] = new_brush
		handle_common(packet)
		var detected_release := false
		var shift: bool = packet.shift
		var can_erase: bool = true#erase_marker_permissions.has(id)
		var pos := Vector2(packet["x"], packet["y"]) * Vector2(1920.0, 1080.0)
		var pos_screen := Vector2(packet["x"], packet["y"]) * Vector2(3840.0, 2160.0)
		var cast_result: Dictionary = cast(pos)
		var tick: int = Time.get_ticks_msec()
		if cast_result.has("position"):
			var cast_collider: Node3D = cast_result["collider"]
			var pos3d: Vector3 = whole_monitor.to_local(cast_result["position"])
			# -3.84 / 2.0 < pos3d.x < 3.84 / 2.0
			var virtual_x: float = remap(pos3d.x, -3.84 / 2.0, 3.84 / 2.0, 0.0, 3840.0)
			var virtual_y: float = -remap(pos3d.y, -2.16 / 2.0, 2.16 / 2.0, -2160.0, 0.0)
			var pos_virtual_screen := Vector2(virtual_x + 1080.0, virtual_y)
			var pos_virtual_screen_2 := Vector2(virtual_x, virtual_y)
			if cast_collider == marker_color_area:
				var pos3d_color: Vector3 = marker_color_area.to_local(cast_result["position"])
				pos3d_color.z = 0.05
				if not viewer_color_donuts.has(id):
					add_color_donut(id, pos3d_color)
				viewer_color_donuts[id].pos = pos3d_color
				var pos2d_topleft: Vector2 = Vector2(pos3d_color.x, pos3d_color.y) + Vector2(1.0, -0.15)
				var pos2d_scaled: Vector2 = pos2d_topleft * Vector2(0.5, -1.0 / 0.3)
				var color_color: Color = marker_palette_color_gradient.sample(pos2d_scaled.x)
				var color_gray: Color = marker_palette_gray_gradient.sample(pos2d_scaled.y)
				var color_mix: Color = color_color
				if pos2d_scaled.x > 0.9:
					if pos2d_scaled.y < 0.5:
						color_mix = Color.WHITE
					else:
						color_mix = Color.BLACK
				else:
					if pos2d_scaled.y < 0.333:
						color_mix = color_mix.lightened(0.5)
					elif pos2d_scaled.y > 0.666:
						color_mix = color_mix.darkened(0.5)
				if packet.type == "drag" or packet.type == "click":
					if viewer_windows.has(id):
						if packet.type == "click":
							colors[id] = color_mix
							viewer_windows[id].clr = color_mix
							brushes[id].clr = color_mix
							brushes[id].render_color_or_colorless()
					elif viewer_windows.size() < MAX_VIEWER_WINDOWS:
						var new_viewer_cursor := ViewerCursor.new()
						new_viewer_cursor.clr = colors[packet.id]
						new_viewer_cursor.pos = pos3d
						new_viewer_cursor.last_input = tick
						whole_monitor.add_child(new_viewer_cursor)
						viewer_cursors[id] = new_viewer_cursor
						
						var new_viewer_window := ViewerWindow.new()
						if marker_display_names.has(id):
							new_viewer_window.display_name = marker_display_names[id]
						else:
							new_viewer_window.display_name = "???"
						#new_viewer_window.pos = pos_virtual_screen
						new_viewer_window.pos = pos_virtual_screen_2
						new_viewer_window.internal_pos = pos_virtual_screen
						new_viewer_window.id = id
						new_viewer_window.clr = colors[packet.id]
						new_viewer_window.leaving.connect(_on_viewer_window_leaving)
						#add_child(new_viewer_window)
						window_paint.add_child(new_viewer_window)
						viewer_windows[id] = new_viewer_window
						
						colors[id] = color_mix
						viewer_windows[id].clr = color_mix
						brushes[id].clr = color_mix
						brushes[id].render_color_or_colorless()
			elif cast_collider == monitor_body:
				if packet.type == "release":
					detected_release = true
				screen_interacted.emit(packet, Vector2(virtual_x, virtual_y), can_erase and shift)
				
				if viewer_cursors.has(id):
					viewer_cursors[id].pos = pos3d
					viewer_cursors[id].last_input = tick
					
					#viewer_windows[id].pos = pos_virtual_screen
					viewer_windows[id].pos = pos_virtual_screen_2
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
					if marker_display_names.has(id):
						new_viewer_window.display_name = marker_display_names[id]
					else:
						new_viewer_window.display_name = "???"
					#new_viewer_window.pos = pos_virtual_screen
					new_viewer_window.pos = pos_virtual_screen_2
					new_viewer_window.internal_pos = pos_virtual_screen
					new_viewer_window.id = id
					new_viewer_window.clr = colors[packet.id]
					new_viewer_window.leaving.connect(_on_viewer_window_leaving)
					#add_child(new_viewer_window)
					window_paint.add_child(new_viewer_window)
					viewer_windows[id] = new_viewer_window
			else:
				if cast_collider.has_meta("img"):
					var pos3d_brush: Vector3 = %BrushStore.to_local(cast_result["position"])
					pos3d_brush.z = 0.08
					if not viewer_brush_donuts.has(id):
						add_brush_donut(id, pos3d_brush)
					viewer_brush_donuts[id].pos = pos3d_brush
					if packet.type == "click":
						var brush_preview: BrushPreview = cast_collider.get_parent()
						#brush_preview.hovered = true
						#brush_preview.highlighted = 1.0
						if brushes.has(id):
							if brush_preview.tiled:
								brushes[id].type = Brush.BrushType.CUSTOM_TILE
								brushes[id].splatter = 0.0
								brushes[id].sparse = 16
							elif brush_preview.default:
								brushes[id].type = Brush.BrushType.ROUND
								brushes[id].splatter = 0.0
								brushes[id].sparse = 0
							else:
								brushes[id].type = Brush.BrushType.CUSTOM
								brushes[id].splatter = brush_preview.spread
								brushes[id].sparse = brush_preview.sparseness
							brushes[id].custom_image = brush_preview.img
							brushes[id].custom_mask = brush_preview.mask
							if brush_preview.mask2:
								brushes[id].custom_mask_2 = brush_preview.mask2
							else:
								brushes[id].clear_custom_mask()
							brushes[id].make_brush()
				if packet.type == "drag":
					detected_release = true
					user_released.emit(id)
		else:
			if packet.type == "drag":
				detected_release = true
				user_released.emit(id)
		
		if packet.type == "release" and not detected_release:
			user_released.emit(id)


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
	query.collide_with_areas = true
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


func _on_game_world_thicker_lines() -> void:
	timer_thicker_lines.start()
	#window_paint.brush_thickness = window_paint.BRUSH_SIZE_THICK
	for id: String in brushes:
		brushes[id].size = 64
		brushes[id].make_brush()


func _on_timer_thicker_lines_timeout() -> void:
	#window_paint.brush_thickness = window_paint.BRUSH_SIZE
	for id: String in brushes:
		brushes[id].size = 12
		brushes[id].make_brush()


func get_system_temps() -> Dictionary[String, float]:
	var output_name: Array[String] = []
	var output_temp: Array[String] = []
	
	var output_dict: Dictionary[String, float] = {}
	
	var exit_code_name = OS.execute("bash", ["-c", "cat /sys/class/hwmon/hwmon*/name"], output_name)
	var exit_code_temp = OS.execute("bash", ["-c", "cat /sys/class/hwmon/hwmon*/temp1_input"], output_temp)
	
	var output_name0 := output_name[0].split("\n")
	var output_temp0 := output_temp[0].split("\n")
	
	for i in output_name0.size():
		var temp: float = output_temp0[i].to_float() / 1000.0
		var o_name: String = output_name0[i]
		while output_dict.has(o_name):
			o_name += "0"
		output_dict[o_name] = temp
	
	return output_dict


func _on_timer_mouse_check_timeout() -> void:
	pass
	#var current_mouse_pos: Vector2i = DisplayServer.mouse_get_position()
	#cursor_speed_rolling.append(Vector2(current_mouse_pos - last_mouse_pos).length_squared())
	#if cursor_speed_rolling.size() > 10:
		#cursor_speed_rolling.remove_at(0)
	#var avg: float = 0.0
	#for speed: float in cursor_speed_rolling:
		#avg += speed
	#avg /= float(cursor_speed_rolling.size())
	#print(avg)
	#last_mouse_pos = current_mouse_pos


func _on_tree_exiting() -> void:
	if stupid_pipe:
		OS.kill(pipe_pid)


func _on_clear_markers_pressed() -> void:
	window_paint.clear()


func _on_game_world_mod_cleared_screen() -> void:
	window_paint.clear()


func _on_game_world_only_mods_draw() -> void:
	mod_markers_only = not mod_markers_only
	if mod_markers_only:
		timer_mods_only_draw.start()
	else:
		timer_mods_only_draw.stop()


func _on_timer_mods_only_draw_timeout() -> void:
	mod_markers_only = false


func _on_game_world_save_drawing() -> void:
	save_drawing.emit()


func _on_game_world_drawing_enabled(user_id: String, display_name: String) -> void:
	if not enabled_drawers.has(user_id):
		enabled_drawers.append(user_id)


func _on_check_button_hide_drawing_toggled(toggled_on: bool) -> void:
	%TextureRect.visible = not toggled_on
	%TextureRectShadow.visible = not toggled_on
