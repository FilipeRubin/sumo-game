class_name MainMenu extends Control

@export var _screens: Array[VBoxContainer]
@export var _first_screen: VBoxContainer
@export var _host_screen: HostScreen

func set_visible_screen(screen: VBoxContainer) -> void:
	for i: VBoxContainer in _screens:
		i.set_visible(i == screen)

func _ready() -> void:
	set_visible_screen(_first_screen)
	_host_screen.created_server.connect(_on_created_server)
	get_multiplayer().connected_to_server.connect(_on_connected_to_server)

func _on_created_server() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.scn")

func _on_connected_to_server() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.scn")
