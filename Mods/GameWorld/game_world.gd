extends Mod_Base


const SENS: float = 0.003
const SPEED: float = 5.0
const JUMP: float = 5.0
const ACCEL: float = 0.1
const ACCEL_AIR: float = 0.04


var default_key_actions: Dictionary[StringName, InputEventKey] = {
				"left": create_input_event_key(KEY_A),
				"right": create_input_event_key(KEY_D),
				"fwd": create_input_event_key(KEY_W),
				"back": create_input_event_key(KEY_S),
				"jump": create_input_event_key(KEY_SPACE)}
var rot_h: float = 0.0
var rot_v: float = -PI/6.0:
	set(value):
		rot_v = clampf(value, -PI/2.1, PI/8.0)


@onready var char: CharacterBody3D = $Window/WorldRoot/CharacterBody3D
@onready var cam_h: Node3D = $Window/WorldRoot/CharacterBody3D/CamH
@onready var cam_v: Node3D = $Window/WorldRoot/CharacterBody3D/CamH/CamV
@onready var spring_arm_3d: SpringArm3D = $Window/WorldRoot/CharacterBody3D/CamH/CamV/SpringArm3D
@onready var cam_holder: Node3D = $Window/WorldRoot/CharacterBody3D/CamH/CamV/SpringArm3D/CamHolder
@onready var camera_3d: Camera3D = $Window/Camera3D
@onready var main_cam_h: Node3D = $Window/WorldRoot/CharacterBody3D/MainCamH
@onready var main_camera_holder: StaticBody3D = $Window/WorldRoot/CharacterBody3D/MainCamH/MainCameraHolder
@onready var rigid_main_camera_holder: RigidBody3D = $Window/WorldRoot/RigidMainCameraHolder


func _ready() -> void:
	for ac in default_key_actions:
		InputMap.add_action(ac)
		InputMap.action_add_event(ac, default_key_actions[ac])


func create_input_event_key(phys_keycode: Key) -> InputEventKey:
	var iek := InputEventKey.new()
	iek.physical_keycode = phys_keycode
	return iek


func _process(delta: float) -> void:
	cam_h.rotation.y = rot_h
	cam_v.rotation.x = rot_v
	
	camera_3d.global_transform = cam_holder.global_transform
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var app = get_app()
		var boom: Node3D = app.find_child("CameraBoom")
		boom.global_transform = rigid_main_camera_holder.global_transform


func _physics_process(delta: float) -> void:
	if not char.is_on_floor():
		char.velocity += char.get_gravity() * delta
	else:
		if Input.is_action_just_pressed("jump") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			char.velocity.y = JUMP
	
	var input := Input.get_vector("left", "right", "fwd", "back")
	var dir := cam_h.global_basis * Vector3(input.x, 0.0, input.y)
	
	var accel: float
	
	if char.is_on_floor():
		accel = ACCEL
	else:
		accel = ACCEL_AIR
	
	if dir and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		char.velocity.x = lerpf(char.velocity.x, dir.x * SPEED, accel)
		char.velocity.z = lerpf(char.velocity.z, dir.z * SPEED, accel)
	else:
		char.velocity.x = lerpf(char.velocity.x, 0.0, accel)
		char.velocity.z = lerpf(char.velocity.z, 0.0, accel)
	
	char.move_and_slide()
	
	var model := get_model()
	if model:
		model.global_position = char.global_position
		
		var dir_2d := Vector2(dir.x, dir.z)
		if dir_2d and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			model.global_rotation.y = lerp_angle(model.global_rotation.y, -dir_2d.angle() + (PI/2.0), 0.1)
		
		main_cam_h.global_rotation.y = lerp_angle(main_cam_h.global_rotation.y, model.global_rotation.y, 0.4)
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var app = get_app()
		var boom: Node3D = app.find_child("CameraBoom")
		#boom.set_process(true)


func _on_window_window_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton:
			if event.button_index == 1:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				var app = get_app()
				var boom: Node3D = app.find_child("CameraBoom")
				#boom.set_process(false)
				main_camera_holder.global_transform = boom.global_transform
	else:
		if event is InputEventMouseMotion:
			rot_h -= event.relative.x * SENS
			rot_v -= event.relative.y * SENS
