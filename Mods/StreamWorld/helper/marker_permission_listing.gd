extends HBoxContainer
class_name MarkerPermissionListing


signal marker_permissions_revoked(id: String, display_name: String)
signal marker_permissions_restored(id: String, display_name: String)


var display_name: String
var id: String
var revoked: bool:
	set(value):
		revoked = value
		if button_restore:
			button_restore.visible = revoked
		if button_revoke:
			button_revoke.visible = not revoked


@onready var label_display_name: Label = $LabelDisplayName
@onready var button_revoke: Button = $ButtonRevoke
@onready var button_restore: Button = $ButtonRestore


func _ready() -> void:
	label_display_name.text = display_name
	button_revoke.visible = not revoked
	button_restore.visible = revoked


func _on_button_revoke_pressed() -> void:
	marker_permissions_revoked.emit(id, display_name)
	revoked = true


func _on_button_restore_pressed() -> void:
	marker_permissions_restored.emit(id, display_name)
	revoked = false
