extends Mod_Base


# lurk makes eyeballs

signal thicker_lines
signal marker_permissions_requested(user_id: String, display_name: String)
signal erase_marker_permissions_requested(user_id: String, display_name: String)
signal revoked_permissions_requested(user_id: String, display_name: String)
signal drawing_enabled(user_id: String, display_name: String)
signal mod_cleared_screen
signal only_mods_draw
signal save_drawing


const SENS: float = 0.003
const SPEED: float = 6.0
const JUMP: float = 3.0
const ACCEL: float = 0.1
const ACCEL_AIR: float = 0.05
const MOD_USERNAMES: Array[String] = [
									"bigbut5", "bucky1729", "fullbonghit",
									"rmct02", "yeahimbong"
									]
const MARKER_PERMISSION_PATH: String = "user://marker_permissions.dat"
const REVOKED_PERMISSION_PATH: String = "user://revoked_permissions.dat"
const DAY_IN_SECONDS: float = 86400.0


@export var pos_override := false
@export var pos_override_value := Vector3.ZERO
@export var island_material: ShaderMaterial


var default_key_actions: Dictionary[StringName, InputEventKey] = {
				"left": create_input_event_key(KEY_A),
				"right": create_input_event_key(KEY_D),
				"fwd": create_input_event_key(KEY_W),
				"back": create_input_event_key(KEY_S),
				"jump": create_input_event_key(KEY_SPACE),
				"face_cam": create_input_event_key(KEY_C)}
var rot_h: float = 0.0
var rot_v: float = -PI/6.0:
	set(value):
		rot_v = clampf(value, -PI/2.1, PI/8.0)
var top_rigid_chat: RigidChat

var player_position: Vector3 = Vector3.ZERO
var player_rotation: float = 0.0
var mod_ids: Array[String] = []
var revoked_marker_ids: Dictionary[String, String] = {}


@onready var world_root: Node3D = $WorldRoot
@onready var chat: AnimatableBody3D = $WorldRoot/Chat
@onready var character_body_3d: CharacterBody3D = $WorldRoot/CharacterBody3D
@onready var cam_h: Node3D = $WorldRoot/CharacterBody3D/CamH
@onready var cam_v: Node3D = $WorldRoot/CharacterBody3D/CamH/CamV
@onready var spring_arm_3d: SpringArm3D = $WorldRoot/CharacterBody3D/CamH/CamV/SpringArm3D
@onready var cam_holder: Node3D = $WorldRoot/CharacterBody3D/CamH/CamV/SpringArm3D/CamHolder
@onready var main_cam_h: Node3D = $WorldRoot/CharacterBody3D/MainCamH
@onready var main_camera_holder: AnimatableBody3D = $WorldRoot/CharacterBody3D/MainCamH/MainCameraHolder
@onready var rigid_main_camera_holder: RigidBody3D = $WorldRoot/RigidMainCameraHolder
@onready var capture: CaptureScene = $WorldRoot/Capture
@onready var window_player: Window = $WindowPlayer
@onready var camera_3d_player: Camera3D = $WindowPlayer/Camera3DPlayer
@onready var window_stream: Window = $WindowStream
@onready var camera_3d_stream: Camera3D = $WindowStream/Camera3DStream
@onready var timer_save_position: Timer = $TimerSavePosition
@onready var timer_save_drawing: Timer = $TimerSaveDrawing
@onready var voice_box: AudioStreamPlayer3D = $VoiceBox


func _ready() -> void:
	#var model = get_model()
	#var anim_player_2 := AnimationPlayer.new()
	#model.add_child(anim_player_2)
	#anim_player_2.name = "AnimationPlayer2"
	##var anim_player : AnimationPlayer = model.find_child("AnimationPlayer", false, false)
	#anim_player_2.add_animation_library("", AnimationLibrary.new())
	#anim_player_2.get_animation_library("").add_animation("Walk", preload("res://Mods/StreamWorld/animation/walk.res"))
	#anim_player_2.play("Walk")
	
	window_stream.visible = true
	for ac in default_key_actions:
		InputMap.add_action(ac)
		InputMap.action_add_event(ac, default_key_actions[ac])
	
	add_tracked_setting(
		"player_position",
		"Player Position"
	)
	add_tracked_setting(
		"player_rotation",
		"Player Rotation"
	)
	
	var root_window: Window = get_tree().root
	root_window.anisotropic_filtering_level = Viewport.ANISOTROPY_DISABLED
	root_window.scaling_3d_scale = 0.25
	root_window.audio_listener_enable_3d = false
	root_window.audio_listener_enable_2d = false
	root_window.positional_shadow_atlas_size = 0
	root_window.disable_3d = true
	
	var revoked_permission_file: FileAccess
	if FileAccess.file_exists(REVOKED_PERMISSION_PATH):
		revoked_permission_file = FileAccess.open(REVOKED_PERMISSION_PATH, FileAccess.READ_WRITE)
	else:
		revoked_permission_file = FileAccess.open(REVOKED_PERMISSION_PATH, FileAccess.WRITE_READ)
	while not revoked_permission_file.eof_reached():
		var user_id: String = revoked_permission_file.get_pascal_string()
		var display_name: String = revoked_permission_file.get_pascal_string()
		revoked_marker_ids[display_name] = user_id
	revoked_permission_file.close()
	
	#for id: String in revoked_marker_ids:
		#pass
	
	var unix_time: float = Time.get_unix_time_from_system()
	var good_marker_permissions: Dictionary[String, float] = {}
	var good_display_names: Dictionary[String, String] = {}
	var marker_permission_file: FileAccess
	if FileAccess.file_exists(MARKER_PERMISSION_PATH):
		marker_permission_file = FileAccess.open(MARKER_PERMISSION_PATH, FileAccess.READ_WRITE)
	else:
		marker_permission_file = FileAccess.open(MARKER_PERMISSION_PATH, FileAccess.WRITE_READ)
	while not marker_permission_file.eof_reached():
		var user_id: String = marker_permission_file.get_pascal_string()
		var display_name: String = marker_permission_file.get_pascal_string()
		var grant_time: float = marker_permission_file.get_double()
		var seconds_diff: float = unix_time - grant_time
		if true:#seconds_diff < DAY_IN_SECONDS:
			good_marker_permissions[user_id] = grant_time
			good_display_names[user_id] = display_name
	marker_permission_file.close()
	marker_permission_file = FileAccess.open(MARKER_PERMISSION_PATH, FileAccess.WRITE)
	for good_id: String in good_marker_permissions:
		var grant_time: float = good_marker_permissions[good_id]
		marker_permission_file.store_pascal_string(good_id)
		marker_permission_file.store_pascal_string(good_display_names[good_id])
		marker_permission_file.store_double(grant_time)
		if not revoked_marker_ids.values().has(good_id):
			marker_permissions_requested.emit(good_id, good_display_names[good_id])
		else:
			revoked_permissions_requested.emit(good_id, good_display_names[good_id])
	marker_permission_file.close()


func load_after(_settings_old : Dictionary, _settings_new : Dictionary) -> void:
	if pos_override:
		character_body_3d.global_position = pos_override_value
		return
	character_body_3d.global_position = player_position


func handle_channel_chat_message_v2(
	chatter_username : String,
	chatter_display_name : String,
	message : String,
	chatter_color : String,
	badges: Array,
	fragment_list : Array,
	bits_count : int):
	
	#prints(chatter_display_name, message)
	if MOD_USERNAMES.has(chatter_username):
		if message == "!clear":
			mod_cleared_screen.emit()
		elif message == "!modsonly":
			only_mods_draw.emit()
	#if message.containsn("!draw"):
	var chatter_data: Dictionary = await get_twitch_id(chatter_username)
	var chatter_id: String = chatter_data.id
	drawing_enabled.emit(chatter_id, chatter_display_name)
	#if message == "!save":
		#if timer_save_drawing.is_stopped():
			#save_drawing.emit()
			#timer_save_drawing.start()
	#if message.countn("b") >= 3:
		#capture.launch_bubble()
	
	#var new_rigid_chat := RigidChat.new()
	#new_rigid_chat.text = message
	#new_rigid_chat.hang_from = chat
	#chat.add_child(new_rigid_chat)
	#
	#if not top_rigid_chat:
		#top_rigid_chat = new_rigid_chat
	#else:
		#top_rigid_chat.rejoin(new_rigid_chat)
		#top_rigid_chat = new_rigid_chat


func handle_channel_point_redeem(
	_redeemer_username,
	_redeemer_display_name,
	_redeem_title,
	_user_input):
	
	#print(_redeem_title)
	if _redeem_title == "Thicker Lines":
		thicker_lines.emit()
	elif _redeem_title == "Save Drawing":
		save_drawing.emit()
	elif _redeem_title == "Marker Permissions":
		var redeemer_data: Dictionary = await get_twitch_id(_redeemer_username)
		#print(redeemer_data)
		var redeemer_id: String = redeemer_data.id
		if not revoked_marker_ids.values().has(redeemer_id):
			marker_permissions_requested.emit(redeemer_id, _redeemer_display_name)
			
			var unix_time: float = Time.get_unix_time_from_system()
			var good_marker_permissions: Dictionary[String, float] = {}
			var good_display_names: Dictionary[String, String] = {}
			var marker_permission_file := FileAccess.open(MARKER_PERMISSION_PATH, FileAccess.READ_WRITE)
			while not marker_permission_file.eof_reached():
				var user_id: String = marker_permission_file.get_pascal_string()
				var display_name: String = marker_permission_file.get_pascal_string()
				var grant_time: float = marker_permission_file.get_double()
				var seconds_diff: float = unix_time - grant_time
				if true:#seconds_diff < DAY_IN_SECONDS:
					good_marker_permissions[user_id] = grant_time
					good_display_names[user_id] = display_name
			marker_permission_file.close()
			marker_permission_file = FileAccess.open(MARKER_PERMISSION_PATH, FileAccess.WRITE)
			good_marker_permissions[redeemer_id] = unix_time
			good_display_names[redeemer_id] = _redeemer_display_name
			for good_id: String in good_marker_permissions:
				var grant_time: float = good_marker_permissions[good_id]
				marker_permission_file.store_pascal_string(good_id)
				marker_permission_file.store_pascal_string(good_display_names[good_id])
				marker_permission_file.store_double(grant_time)
			marker_permission_file.close()
		else:
			revoked_permissions_requested.emit(redeemer_id, _redeemer_display_name)


func get_twitch_id(username: String) -> Dictionary:
	var app = get_app()
	var mods = app.get_node("Mods")
	var twitch_integration: Mod_Base = mods.get_node("TwitchIntegration")
	if twitch_integration:
		var twitch_service: TwitchService = twitch_integration.get_child(0)
		return await twitch_service.lookup_user_async(username)
	return {}


func create_input_event_key(phys_keycode: Key) -> InputEventKey:
	var iek := InputEventKey.new()
	iek.physical_keycode = phys_keycode
	return iek


func _process(delta: float) -> void:
	cam_h.rotation.y = rot_h
	cam_v.rotation.x = rot_v

	camera_3d_player.global_transform = cam_holder.global_transform

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var app = get_app()
		var boom: Node3D = app.find_child("CameraBoom")
		boom.global_transform = rigid_main_camera_holder.global_transform


func _physics_process(delta: float) -> void:
	var skel = get_skeleton()
	var head: Node3D = skel.get_node_or_null("HeadOutside")
	if head:
		voice_box.global_transform = head.global_transform
		voice_box.global_basis = voice_box.global_basis.rotated(voice_box.global_basis.y, PI)
	
	if not character_body_3d.is_on_floor():
		character_body_3d.velocity += character_body_3d.get_gravity() * delta
	else:
		if Input.is_action_just_pressed("jump") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			character_body_3d.velocity.y = JUMP

	var input := Input.get_vector("left", "right", "fwd", "back")
	var dir := cam_h.global_basis * Vector3(input.x, 0.0, input.y)
	
	if input:
		timer_save_position.start()

	var accel: float

	if character_body_3d.is_on_floor():
		accel = ACCEL
	else:
		accel = ACCEL_AIR

	if dir and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		character_body_3d.velocity.x = lerpf(character_body_3d.velocity.x, dir.x * SPEED, accel)
		character_body_3d.velocity.z = lerpf(character_body_3d.velocity.z, dir.z * SPEED, accel)
	else:
		character_body_3d.velocity.x = lerpf(character_body_3d.velocity.x, 0.0, accel)
		character_body_3d.velocity.z = lerpf(character_body_3d.velocity.z, 0.0, accel)

	character_body_3d.move_and_slide()

	var model := get_model_controller()
	if model:
		model.global_position = character_body_3d.global_position
		var dir_2d := Vector2(dir.x, dir.z)
		var look_angle: float
		if Input.is_action_pressed("face_cam"):
			var dir_to_cam: Vector3 = model.global_position.direction_to(camera_3d_stream.global_position)
			var dir_to_cam_2d := Vector2(dir_to_cam.x, dir_to_cam.z)
			look_angle = -dir_to_cam_2d.angle() + (PI/2.0)
		else:
			look_angle = -dir_2d.angle() + (PI/2.0)

		if (dir_2d or Input.is_action_pressed("face_cam")) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			player_rotation = lerp_angle(player_rotation, look_angle, 0.1)

		main_cam_h.global_rotation.y = lerp_angle(main_cam_h.global_rotation.y, model.global_rotation.y, 0.4)

	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var app = get_app()
		var boom: Node3D = app.find_child("CameraBoom")
	
	player_position = character_body_3d.global_position
	model.global_rotation.y = player_rotation


func _on_window_window_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton:
			if event.button_index == 1:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				var app = get_app()
				var boom: Node3D = app.find_child("CameraBoom")
				main_camera_holder.global_transform = boom.global_transform
	else:
		if event is InputEventMouseMotion:
			rot_h -= event.relative.x * SENS
			rot_v -= event.relative.y * SENS


func _on_timer_5s_timeout() -> void:
	for mod_name: String in MOD_USERNAMES:
		var mod_data: Dictionary = await get_twitch_id(mod_name)
		var mod_id: String = mod_data.id
		mod_ids.append(mod_id)
		var star: String = String.chr(9733)
		marker_permissions_requested.emit(mod_id, star + mod_name)
		erase_marker_permissions_requested.emit(mod_id, star + mod_name)


func _on_window_tools_marker_permissions_revoked(user_id: String, display_name: String) -> void:
	revoked_marker_ids[display_name] = user_id
	var revoked_permission_file := FileAccess.open(REVOKED_PERMISSION_PATH, FileAccess.WRITE)
	for _display_name: String in revoked_marker_ids:
		revoked_permission_file.store_pascal_string(revoked_marker_ids[_display_name])
		revoked_permission_file.store_pascal_string(_display_name)
	revoked_permission_file.close()


func _on_window_tools_marker_permissions_restored(user_id: String, display_name: String) -> void:
	revoked_marker_ids.erase(display_name)
	var revoked_permission_file := FileAccess.open(REVOKED_PERMISSION_PATH, FileAccess.WRITE)
	for _display_name: String in revoked_marker_ids:
		revoked_permission_file.store_pascal_string(revoked_marker_ids[_display_name])
		revoked_permission_file.store_pascal_string(_display_name)
	revoked_permission_file.close()


func _on_timer_save_position_timeout() -> void:
	var app = get_app()
	app.save_settings()
	print("autosaving")


func _on_timer_save_drawing_timeout() -> void:
	pass # Replace with function body.


func _on_check_button_asmr_toggled(toggled_on: bool) -> void:
	if toggled_on:
		voice_box.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
		voice_box.panning_strength = 1.0
		voice_box.emission_angle_enabled = true
	else:
		voice_box.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
		voice_box.panning_strength = 0.0
		voice_box.emission_angle_enabled = false


func _on_window_player_mouse_entered() -> void:
	window_player.scaling_3d_scale = 1.0


func _on_window_player_mouse_exited() -> void:
	window_player.scaling_3d_scale = 0.5
