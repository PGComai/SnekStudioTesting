extends Mod_Base


# lurk makes eyeballs

signal thicker_lines


const SENS: float = 0.003
const SPEED: float = 2.0
const JUMP: float = 1.0
const ACCEL: float = 0.1
const ACCEL_AIR: float = 0.05


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


func _ready() -> void:
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


func load_after(_settings_old : Dictionary, _settings_new : Dictionary) -> void:
	character_body_3d.global_position = player_position


func handle_channel_chat_message_v2(
	chatter_username : String,
	chatter_display_name : String,
	message : String,
	chatter_color : String,
	badges: Array,
	fragment_list : Array,
	bits_count : int):
	
	pass
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
	
	print(_redeem_title)
	if _redeem_title == "Thicker Lines":
		thicker_lines.emit()


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
	if not character_body_3d.is_on_floor():
		character_body_3d.velocity += character_body_3d.get_gravity() * delta
	else:
		if Input.is_action_just_pressed("jump") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			character_body_3d.velocity.y = JUMP

	var input := Input.get_vector("left", "right", "fwd", "back")
	var dir := cam_h.global_basis * Vector3(input.x, 0.0, input.y)

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
			player_rotation = lerp_angle(player_rotation, look_angle, 0.02)

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
