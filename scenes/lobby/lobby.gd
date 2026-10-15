class_name Lobby extends Control

signal start_pressed(map_index: int)

const PLAYER_LIST_ENTRY: PackedScene = preload("res://scenes/lobby/player-list-entry.scn")

@export var _player_list: VBoxContainer
@export var _start_button: Button
@export var _map_selector: OptionButton
@export var _leave_button: Button

func _ready() -> void:
	_leave_button.pressed.connect(_on_leave_pressed)
	
	if get_multiplayer().is_server():
		_map_selector.set_disabled(false)
		_start_button.set_disabled(false)
		_start_button.pressed.connect(_on_start_button_pressed)
		var entry: PlayerListEntry = PLAYER_LIST_ENTRY.instantiate()
		_player_list.add_child(entry, true)
		entry.id = get_multiplayer().get_unique_id()
		entry.set_player_name(Globals.player_name)
		for id: int in get_multiplayer().get_peers():
			var peer_entry: PlayerListEntry = PLAYER_LIST_ENTRY.instantiate()
			_player_list.add_child(peer_entry, true)
			peer_entry.id = id
			_request_send_player_name.rpc_id(id)
		get_multiplayer().peer_connected.connect(_on_peer_connected)
		get_multiplayer().peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	var entry: PlayerListEntry = PLAYER_LIST_ENTRY.instantiate()
	_player_list.add_child(entry, true)
	entry.id = id
	_request_send_player_name.rpc_id(id)

func _on_peer_disconnected(id: int) -> void:
	for i: PlayerListEntry in _player_list.get_children():
		if i.id == id:
			i.queue_free()

func _on_start_button_pressed() -> void:
	start_pressed.emit(_map_selector.get_selected())

func _on_leave_pressed() -> void:
	get_multiplayer().get_multiplayer_peer().close()
	get_multiplayer().set_multiplayer_peer(OfflineMultiplayerPeer.new())
	get_tree().change_scene_to_file("res://scenes/main-menu/main-menu.scn")

@rpc("authority", "call_remote", "reliable")
func _request_send_player_name() -> void:
	_send_player_name_to_server.rpc_id(1, Globals.player_name)

@rpc("any_peer", "call_remote", "reliable")
func _send_player_name_to_server(player_name: String) -> void:
	for i: PlayerListEntry in _player_list.get_children():
		if i.id == get_multiplayer().get_remote_sender_id():
			i.set_player_name(player_name)
