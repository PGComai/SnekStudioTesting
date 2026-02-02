extends Mod_Base


const AXES: Dictionary[String, String] = {"X": "X", "Y": "Y", "Z": "Z"}


var model_name: String = ""
var axis: Array = ["X"]
var speed: float = 0.0
var replaced := false


func _ready() -> void:
	add_tracked_setting("model_name", "Model name")
	add_tracked_setting(
		"speed", "Speed",
		{ "min" : -100.0, "max" : 100.0 })
	add_tracked_setting("axis", "Rotation Axis", {"values" : AXES.keys(), "combobox" : true})
	update_settings_ui()


func _process(delta: float) -> void:
	var skel = get_skeleton()
	var model = skel.get_node_or_null(model_name)
	if model:
		var model_mesh = model.get_child(0)
		if axis[0] == "X":
			model_mesh.rotation.x += delta * speed
			model_mesh.rotation.y = 0.0
			model_mesh.rotation.z = 0.0
		elif axis[0] == "Y":
			model_mesh.rotation.x = 0.0
			model_mesh.rotation.y += delta * speed
			model_mesh.rotation.z = 0.0
		else:
			model_mesh.rotation.x = 0.0
			model_mesh.rotation.y = 0.0
			model_mesh.rotation.z += delta * speed
