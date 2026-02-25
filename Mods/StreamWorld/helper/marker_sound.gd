extends AudioStreamPlayer
class_name MarkerSound


const DRY_ERASE_DRAG_SQUEAK = preload("res://Mods/StreamWorld/audio/dry erase drag squeak.wav")
const DRY_ERASE_DRAG = preload("res://Mods/StreamWorld/audio/dry erase drag.wav")
const DRY_ERASE_HARD_SQUEAK = preload("res://Mods/StreamWorld/audio/dry erase hard squeak.wav")
const DRY_ERASE_SHORT_SQUEAK = preload("res://Mods/StreamWorld/audio/dry erase short squeak.wav")
const DRY_ERASE_SLIDE_2 = preload("res://Mods/StreamWorld/audio/dry erase slide 2.wav")
const DRY_ERASE_SLIDE_DRAG = preload("res://Mods/StreamWorld/audio/dry erase slide drag.wav")
const DRY_ERASE_SLIDE = preload("res://Mods/StreamWorld/audio/dry erase slide.wav")
const DRY_ERASE_SOFT_DRAG = preload("res://Mods/StreamWorld/audio/dry erase soft drag.wav")
const DRY_ERASE_SOFT_SQUEAK = preload("res://Mods/StreamWorld/audio/dry erase soft squeak.wav")
const DRY_ERASE_SQUEAK_DRAG = preload("res://Mods/StreamWorld/audio/dry erase squeak drag.wav")


func _ready() -> void:
	bus = "Marker"
	finished.connect(queue_free)
