extends Node3D
class_name ColorDonut


signal bye(id: String)


const TIMER_TIME: float = 2.0


var mat: Material
var pos: Vector3:
	set(value):
		pos = value
		if timer:
			timer.start()
var id: String
var timer: Timer
var donut_mesh: MeshInstance3D


func _ready() -> void:
	donut_mesh = MeshInstance3D.new()
	var new_torus_mesh := TorusMesh.new()
	new_torus_mesh.inner_radius = 0.03
	new_torus_mesh.outer_radius = 0.045
	new_torus_mesh.rings = 16
	new_torus_mesh.ring_segments = 8
	donut_mesh.mesh = new_torus_mesh
	donut_mesh.material_override = mat
	add_child(donut_mesh)
	donut_mesh.rotation.x = PI/2.0
	donut_mesh.scale = Vector3.ZERO
	position = pos
	
	timer = Timer.new()
	timer.wait_time = TIMER_TIME
	timer.autostart = true
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
	bye.emit(id)
	queue_free()


func _process(delta: float) -> void:
	position = position.lerp(pos, 0.1)
	var scale_factor: float = clampf(remap(timer.time_left, 0.0, TIMER_TIME / 2.0, 0.0, 1.0), 0.0, 1.0)
	donut_mesh.scale = donut_mesh.scale.lerp(Vector3(scale_factor, scale_factor, scale_factor), 0.2)
