extends Mod_Base


var bone_name: String = ""
var model_name: String = ""
var show_if_tracking: bool = true


func _ready() -> void:
	add_tracked_setting("bone_name", "Bone name")
	add_tracked_setting("model_name", "Model name")
	add_tracked_setting("show_if_tracking", "Show if tracking")
	update_settings_ui()


func _handle_global_mod_message(_key : String, _values : Dictionary) -> void:
	if _key == "head_tracking_changed":
		var skel = get_skeleton()
		var bone = skel.get_node_or_null(bone_name)
		if not bone:
			prints("HeadTrackingToggler couldn't fine bone:", bone_name)
			return
		var model = bone.get_node_or_null(model_name)
		if model:
			if show_if_tracking:
				model.visible = _values.is_tracking
			else:
				model.visible = not _values.is_tracking
		else:
			prints("HeadTrackingToggler couldn't fine model:", model_name)
