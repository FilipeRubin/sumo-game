class_name GameMatch extends Node

signal back_to_lobby_requested()

const MAPS: Array[PackedScene] = [
	preload("res://maps/map0/map0.scn")
]

@export var _map_container: Node
@export var _pause_menu: PauseMenu

func start_map(map_index: int) -> void:
	_map_container.add_child(MAPS[map_index].instantiate())

func _ready() -> void:
	_pause_menu.set_visible(false)
	_pause_menu.resume_pressed.connect(_on_pause_menu_resume_pressed)
	_pause_menu.leave_pressed.connect(_on_pause_menu_leave_pressed)
	if get_multiplayer().is_server():
		_pause_menu.lobby_pressed.connect(_on_pause_menu_lobby_pressed)

func _process(_delta: float):
	if Input.is_action_just_pressed("ui_close_dialog"):
		_pause_menu.set_visible(not _pause_menu.is_visible())

func _on_pause_menu_resume_pressed() -> void:
	_pause_menu.set_visible(false)

func _on_pause_menu_lobby_pressed() -> void:
	back_to_lobby_requested.emit()

func _on_pause_menu_leave_pressed() -> void:
	get_multiplayer().get_multiplayer_peer().close()
	get_multiplayer().set_multiplayer_peer(OfflineMultiplayerPeer.new())
	get_tree().change_scene_to_file("res://scenes/main-menu/main-menu.scn")
