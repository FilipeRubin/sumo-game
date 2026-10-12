class_name GameServer extends Node

const LOBBY: PackedScene = preload("res://scenes/lobby/lobby.scn")
const GAME_MATCH: PackedScene = preload("res://scenes/game-match/game-match.scn")

@export var _scene_root: Node

var players_emblems: Dictionary[int, Image] = {}

func _ready() -> void:
	if get_multiplayer().is_server():
		var lobby: Lobby = LOBBY.instantiate()
		lobby.start_pressed.connect(_on_start_pressed)
		_scene_root.add_child(lobby, true)
	else:
		get_multiplayer().server_disconnected.connect(_on_server_disconnected)

func _on_server_disconnected() -> void:
	get_tree().change_scene_to_file("res://scenes/main-menu/main-menu.scn")

func _on_start_pressed(map_index: int) -> void:
	for i: Node in _scene_root.get_children():
		i.queue_free()
	var game_match: GameMatch = GAME_MATCH.instantiate()
	game_match.back_to_lobby_requested.connect(_on_back_to_lobby_requested)
	_scene_root.add_child(game_match, true)
	game_match.start_map(map_index)

func _on_back_to_lobby_requested() -> void:
	for i: Node in _scene_root.get_children():
		i.queue_free()
	var lobby: Lobby = LOBBY.instantiate()
	lobby.start_pressed.connect(_on_start_pressed)
	_scene_root.add_child(lobby, true)
