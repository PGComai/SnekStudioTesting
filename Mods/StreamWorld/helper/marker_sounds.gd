extends Node3D


const SQUEAK_MIN_ANGLE: float = PI/2.0


var drags: Dictionary[String, PackedVector2Array] = {}
var last_audio: Dictionary[String, int] = {}


func _process(delta: float) -> void:
	for id in drags:
		var drag: PackedVector2Array = drags[id]
		var drag_dist: float = 0.0
		var drag_jerk: float = 0.0
		var drag_max_angle: float = 0.0
		var first_angle: float = 0.0
		var last_angle: float = 0.0
		if drag.size() > 3:
			for i in drag.size() - 1:
				var pt0: Vector2 = drag[i]
				var pt1: Vector2 = drag[i+1]
				drag_dist += pt0.distance_squared_to(pt1)
				var ang: float = pt0.direction_to(pt1).angle()
				if i == 0:
					first_angle = ang
				if i > 0 and i < drag.size() - 2:
					drag_jerk += absf(angle_difference(last_angle, ang))
				last_angle = ang
				drag_max_angle = absf(angle_difference(last_angle, first_angle))
			#prints(drag_dist, drag_jerk)
			drags[id] = PackedVector2Array([drag[-2], drag[-1]])
			
			var audio_time: int = Time.get_ticks_msec()
			var can_play_audio := false
			
			if last_audio.has(id):
				if audio_time - last_audio[id] > 100:
					can_play_audio = true
			else:
				can_play_audio = true
			
			if can_play_audio:
				if drag_max_angle > SQUEAK_MIN_ANGLE:
					var dist_effect: float = clampf(remap(-drag_dist, -50000.0, 0.0, 0.0, 15.0), 0.0, 15.0)
					var new_squeak_sound := MarkerSound.new()
					new_squeak_sound.stream = MarkerSound.DRY_ERASE_SHORT_SQUEAK
					new_squeak_sound.autoplay = true
					new_squeak_sound.pitch_scale = randfn(1.0, 0.05)
					var squeak_volume: float = clampf(remap(drag_max_angle, SQUEAK_MIN_ANGLE, PI, -10.0, 0.0) + randfn(0.0, 1.0), -10.0, 0.0)
					new_squeak_sound.volume_db = squeak_volume - dist_effect
					add_child(new_squeak_sound)
					last_audio[id] = audio_time


func _on_capture_scene_screen_interacted(packet: Dictionary, virtual_screen_pos: Vector2, eraser: bool) -> void:
	if packet.type == "drag":
		if drags.has(packet.id):
			var drag: PackedVector2Array = drags[packet.id]
			drag.append(virtual_screen_pos)
			drags[packet.id] = drag
		else:
			drags[packet.id] = PackedVector2Array([virtual_screen_pos])
	elif packet.type == "release":
		if drags.has(packet.id):
			drags.erase(packet.id)


func _on_capture_scene_user_released(id: String) -> void:
	if drags.has(id):
		drags.erase(id)
