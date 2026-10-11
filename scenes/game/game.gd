class_name Game extends Node

const LOBBY: PackedScene = preload("res://scenes/lobby/lobby.scn")

@export var _scene_root: Node

func _ready() -> void:
	if get_multiplayer().is_server():
		_scene_root.add_child(LOBBY.instantiate())
	else:
		get_multiplayer().server_disconnected.connect(_on_server_disconnected)

func _on_server_disconnected() -> void:
	get_tree().change_scene_to_file("res://scenes/main-menu/main-menu.scn")
