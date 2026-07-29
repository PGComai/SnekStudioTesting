extends Node3D
class_name StreamerCar


const SPEED: float = 10.0


var player_in_car := false


@onready var cam_pos: Node3D = $Body/CamPos
@onready var soft_wheel_fr: SoftWheel = $SoftWheelFR
@onready var soft_wheel_fl: SoftWheel = $SoftWheelFL
@onready var soft_wheel_br: SoftWheel = $SoftWheelBR
@onready var soft_wheel_bl: SoftWheel = $SoftWheelBL
@onready var body: RigidBody3D = $Body


func _physics_process(delta: float) -> void:
	var input := Input.get_axis("fwd", "back")
	
	if player_in_car:
		soft_wheel_bl.joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		soft_wheel_br.joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		
		soft_wheel_bl.joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 4.0)
		soft_wheel_br.joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 4.0)
		
		soft_wheel_bl.joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, input * SPEED)
		soft_wheel_br.joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, input * SPEED)
		
		soft_wheel_fl.joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		soft_wheel_fr.joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		
		soft_wheel_fl.joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 4.0)
		soft_wheel_fr.joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 4.0)
		
		soft_wheel_fl.joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, input * SPEED)
		soft_wheel_fr.joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, input * SPEED)
