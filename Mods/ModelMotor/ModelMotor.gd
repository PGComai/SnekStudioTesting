extends Mod_Base


const AXES: Dictionary[String, String] = {"X": "X", "Y": "Y", "Z": "Z"}


var bone_name: String = ""
var model_name: String = ""
var axis: Array = ["X"]
var speed: float = 0.0
var replaced := false
var affected_by_head_tracking := false
var spin_if_head_tracking := true
var head_tracking := false:
	set(value):
		if head_tracking != value:
			head_tracking = value
			if spin_if_head_tracking:
				spinning_up = head_tracking
				spinning_down = not head_tracking
			else:
				spinning_up = not head_tracking
				spinning_down = head_tracking
			if spinning_up:
				timer_spin_change.wait_time = 1.0
			elif spinning_down:
				timer_spin_change.wait_time = 3.0
			timer_spin_change.start()
var head_tracking_effect: float = 0.0
var spinning_up := false
var spinning_down := false


@onready var timer_spin_change: Timer = $TimerSpinChange


func _ready() -> void:
	add_tracked_setting("bone_name", "Bone name")
	add_tracked_setting("model_name", "Model name")
	add_tracked_setting(
		"speed", "Speed",
		{ "min" : -100.0, "max" : 100.0 })
	add_tracked_setting("axis", "Rotation Axis", {"values" : AXES.keys(), "combobox" : true})
	add_tracked_setting("affected_by_head_tracking", "Affected by head tracking")
	add_tracked_setting("spin_if_head_tracking", "Spin if head tracking")
	update_settings_ui()


func _handle_global_mod_message(_key : String, _values : Dictionary) -> void:
	if _key == "head_tracking_changed":
		head_tracking = _values.is_tracking


func _process(delta: float) -> void:
	var skel = get_skeleton()
	var bone = skel.get_node_or_null(bone_name)
	if not bone:
		prints("Motor couldn't find bone:", bone_name)
		return
	var model = bone.get_node_or_null(model_name)
	if model:
		if affected_by_head_tracking:
			if spinning_up:
				head_tracking_effect = Tween.interpolate_value(
											0.0,
											1.0,
											timer_spin_change.wait_time - timer_spin_change.time_left,
											timer_spin_change.wait_time,
											Tween.TRANS_ELASTIC,
											Tween.EASE_IN
										)
			elif spinning_down:
				head_tracking_effect = Tween.interpolate_value(
											1.0,
											-1.0,
											timer_spin_change.wait_time - timer_spin_change.time_left,
											timer_spin_change.wait_time,
											Tween.TRANS_SPRING,
											Tween.EASE_IN_OUT
										)
		else:
			head_tracking_effect = 1.0
		#var model_mesh = model.get_child(0)
		if axis[0] == "X":
			model.rotation.x += delta * speed * head_tracking_effect
			model.rotation.y = 0.0
			model.rotation.z = 0.0
		elif axis[0] == "Y":
			model.rotation.x = 0.0
			model.rotation.y += delta * speed * head_tracking_effect
			model.rotation.z = 0.0
		else:
			model.rotation.x = 0.0
			model.rotation.y = 0.0
			model.rotation.z += delta * speed * head_tracking_effect
	else:
		prints("Motor couldn't find model:", model_name)
