extends Node


func _ready() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(9000, 2)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_multiplayer_peer_connected)
	multiplayer.peer_disconnected.connect(_on_multiplayer_peer_disconnected)


func _on_multiplayer_peer_connected(id: int) -> void:
	prints("multiplayer peer connected:", str(id))


func _on_multiplayer_peer_disconnected(id: int) -> void:
	prints("multiplayer peer disconnected:", str(id))


@rpc("authority", "call_remote", "reliable", 0)
func sync_head_xform(xform: Transform3D) -> void:
	pass


@rpc("authority", "call_remote", "reliable", 0)
func sync_cam_xform(xform: Transform3D) -> void:
	pass


@rpc("authority", "call_remote", "reliable", 0)
func set_voice_settings(settings: Dictionary) -> void:
	pass
