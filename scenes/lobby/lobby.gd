class_name Lobby extends Control

const PLAYER_LIST_ENTRY: PackedScene = preload("res://scenes/lobby/player-list-entry.scn")

@export var _player_list: VBoxContainer

func _ready() -> void:
	if get_multiplayer().is_server():
		var entry: PlayerListEntry = PLAYER_LIST_ENTRY.instantiate()
		_player_list.add_child(entry, true)
		entry.set_player_name(str(get_multiplayer().get_unique_id()))
		get_multiplayer().peer_connected.connect(_on_peer_connected)
		get_multiplayer().peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	var entry: PlayerListEntry = PLAYER_LIST_ENTRY.instantiate()
	_player_list.add_child(entry, true)
	entry.set_player_name(str(id))

func _on_peer_disconnected(id: int) -> void:
	for i: PlayerListEntry in _player_list.get_children():
		if i.get_player_name() == str(id):
			i.queue_free()
