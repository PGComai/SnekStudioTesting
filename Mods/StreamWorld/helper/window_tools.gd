extends Window


signal marker_permissions_revoked(user_id: String, display_name: String)
signal marker_permissions_restored(user_id: String, display_name: String)


const SETTINGS_PATH: String = "user://gameworld_settings.dat"
const MARKER_PERMISSION_LISTING = preload("res://Mods/StreamWorld/helper/marker_permission_listing.tscn")


var permission_listings: Dictionary[String, MarkerPermissionListing] = {}


@onready var check_button_brb: CheckButton = $VBoxContainer/CheckButtonBRB
@onready var label_marker_volume: Label = $VBoxContainer/HBoxContainer/LabelMarkerVolume
@onready var h_slider_marker_audio: HSlider = $VBoxContainer/HBoxContainer/HSliderMarkerAudio
@onready var scroll_container_marker_permissions: ScrollContainer = $VBoxContainer/ScrollContainerMarkerPermissions
@onready var v_box_container_marker_permissions: VBoxContainer = $VBoxContainer/ScrollContainerMarkerPermissions/VBoxContainerMarkerPermissions


func _ready() -> void:
	var settings_file: FileAccess
	var marker_volume: float = 0.0
	if FileAccess.file_exists(SETTINGS_PATH):
		settings_file = FileAccess.open(SETTINGS_PATH, FileAccess.READ_WRITE)
		marker_volume = settings_file.get_double()
	else:
		settings_file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE_READ)
	settings_file.close()
	_on_h_slider_marker_audio_value_changed(marker_volume)
	h_slider_marker_audio.set_value_no_signal(marker_volume)


func _on_check_button_brb_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_h_slider_marker_audio_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Marker"), value)
	label_marker_volume.text = "Marker volume: %s db" % snappedf(value, 0.1)
	
	var settings_file: FileAccess
	settings_file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE_READ)
	settings_file.store_double(value)
	settings_file.close()


func _on_game_world_marker_permissions_requested(user_id: String, display_name: String) -> void:
	if not permission_listings.has(user_id):
		var new_permission_listing: MarkerPermissionListing = MARKER_PERMISSION_LISTING.instantiate()
		new_permission_listing.revoked = false
		new_permission_listing.id = user_id
		new_permission_listing.display_name = display_name
		new_permission_listing.marker_permissions_revoked.connect(_on_marker_permissions_revoked)
		new_permission_listing.marker_permissions_restored.connect(_on_marker_permissions_restored)
		v_box_container_marker_permissions.add_child(new_permission_listing)
		permission_listings[user_id] = new_permission_listing
	else:
		permission_listings[user_id].revoked = false


func _on_marker_permissions_revoked(user_id: String, display_name: String) -> void:
	marker_permissions_revoked.emit(user_id, display_name)


func _on_marker_permissions_restored(user_id: String, display_name: String) -> void:
	marker_permissions_restored.emit(user_id, display_name)


func _on_game_world_revoked_permissions_requested(user_id: String, display_name: String) -> void:
	if not permission_listings.has(user_id):
		var new_permission_listing: MarkerPermissionListing = MARKER_PERMISSION_LISTING.instantiate()
		new_permission_listing.revoked = true
		new_permission_listing.id = user_id
		new_permission_listing.display_name = display_name
		new_permission_listing.marker_permissions_revoked.connect(_on_marker_permissions_revoked)
		new_permission_listing.marker_permissions_restored.connect(_on_marker_permissions_restored)
		v_box_container_marker_permissions.add_child(new_permission_listing)
		permission_listings[user_id] = new_permission_listing
	else:
		permission_listings[user_id].revoked = true
