extends Mod_Base


var audio_path_tracking: String = "":
	set(value):
		if audio_path_tracking != value:
			if FileAccess.file_exists(value):
				if value.ends_with(".mp3")\
				or value.ends_with(".wav")\
				or value.ends_with(".ogg")\
				or value.ends_with(".oga"):
					audio_path_tracking = value
					audio_stream_tracking = load_audio(audio_path_tracking)
					if not audio_stream_player_tracking:
						await ready
					audio_stream_player_tracking.stream = audio_stream_tracking
var audio_stream_tracking: AudioStream
var volume_tracking: float = 0.0:
	set(value):
		if volume_tracking != value:
			volume_tracking = value
			if not audio_stream_player_tracking:
				await ready
			audio_stream_player_tracking.volume_db = volume_tracking
var audio_path_lost_tracking: String = "":
	set(value):
		if audio_path_lost_tracking != value:
			if FileAccess.file_exists(value):
				if value.ends_with(".mp3")\
				or value.ends_with(".wav")\
				or value.ends_with(".ogg")\
				or value.ends_with(".oga"):
					audio_path_lost_tracking = value
					audio_stream_lost_tracking = load_audio(audio_path_lost_tracking)
					if not audio_stream_player_lost_tracking:
						await ready
					audio_stream_player_lost_tracking.stream = audio_stream_lost_tracking
var audio_stream_lost_tracking: AudioStream
var volume_lost_tracking: float = 0.0:
	set(value):
		if volume_lost_tracking != value:
			volume_lost_tracking = value
			if not audio_stream_player_lost_tracking:
				await ready
			audio_stream_player_lost_tracking.volume_db = volume_lost_tracking
var min_time_between_sounds: float = 1.0


@onready var audio_stream_player_tracking: AudioStreamPlayer = $AudioStreamPlayerTracking
@onready var audio_stream_player_lost_tracking: AudioStreamPlayer = $AudioStreamPlayerLostTracking
@onready var timer_between_sounds: Timer = $TimerBetweenSounds


func _ready() -> void:
	add_tracked_setting("audio_path_tracking", "Audio path tracking",
				{"is_fileaccess": true})
	add_tracked_setting("audio_path_lost_tracking", "Audio path lost tracking",
				{"is_fileaccess": true})
	add_tracked_setting("min_time_between_sounds", "Minimum time between sounds",
				{"min": 0.0, "max": 10.0})
	add_tracked_setting("volume_tracking", "Tracking sound volume",
				{"min": -80.0, "max": 24.0})
	add_tracked_setting("volume_lost_tracking", "Lost tracking sound volume",
				{"min": -80.0, "max": 24.0})
	update_settings_ui()


func _handle_global_mod_message(_key : String, _values : Dictionary) -> void:
	if _key == "head_tracking_changed":
		if timer_between_sounds.is_stopped():
			if _values.is_tracking:
				audio_stream_player_tracking.play()
			else:
				audio_stream_player_lost_tracking.play()
			if min_time_between_sounds:
				timer_between_sounds.start(min_time_between_sounds)


func load_audio(path: String) -> AudioStream:
	#label_custom_sound.text = path.get_slice("/", path.get_slice_count("/") - 1)
	#line_edit_custom_sound.text = path
	#line_edit_custom_sound.caret_column = path.length()
	print("loading audio path: %s" % path)
	var stream: AudioStream
	#var file := FileAccess.open(path, FileAccess.READ)
	if path.ends_with(".mp3"):
		stream = AudioStreamMP3.load_from_file(path)
		#stream.data = file.get_buffer(file.get_length())
	elif path.ends_with(".wav"):
		stream = AudioStreamWAV.load_from_file(path)
		#stream.data = file.get_buffer(file.get_length())
	elif path.ends_with(".ogg") or path.ends_with(".oga"):
		stream = AudioStreamOggVorbis.load_from_file(path)
	return stream


func _on_timer_between_sounds_timeout() -> void:
	pass # Replace with function body.
