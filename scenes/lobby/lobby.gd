class_name Lobby extends Control

signal start_pressed(map_index: int)

const PLAYER_LIST_ENTRY: PackedScene = preload("res://scenes/lobby/player-list-entry.scn")

@export var _player_list: VBoxContainer
@export var _start_button: Button
@export var _map_selector: OptionButton

func _ready() -> void:
	if get_multiplayer().is_server():
		_map_selector.set_disabled(false)
		_start_button.set_disabled(false)
		_start_button.pressed.connect(_on_start_button_pressed)
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

func _on_start_button_pressed() -> void:
	start_pressed.emit(_map_selector.get_selected())
