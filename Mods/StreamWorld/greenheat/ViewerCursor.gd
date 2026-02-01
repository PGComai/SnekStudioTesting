extends Node3D
class_name ViewerCursor


var clr: Color
var pos: Vector3
var mat: StandardMaterial3D
var last_input: int
var og_alpha: float


func _ready() -> void:
	og_alpha = clr.a
	var new_mesh_inst := MeshInstance3D.new()
	var new_mesh := SphereMesh.new()
	new_mesh.radius = 0.1
	new_mesh.height = 0.2
	
	var new_mat := StandardMaterial3D.new()
	new_mat.albedo_color = clr
	#new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	
	new_mesh_inst.mesh = new_mesh
	new_mesh_inst.material_override = new_mat
	add_child(new_mesh_inst)
	mat = new_mat
	visible = false


func _process(delta: float) -> void:
	position = position.lerp(pos, 0.1)
	var age: int = Time.get_ticks_msec() - last_input
	var a: float = clampf(remap(-float(age), -13000.0, -10000.0, 0.0, og_alpha), 0.0, og_alpha)
	mat.albedo_color.a = a
