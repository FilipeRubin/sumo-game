class_name GameMatch extends Node

signal back_to_lobby_requested()

const MAPS: Array[PackedScene] = [
	preload("res://maps/map0/map0.scn")
]

@export var _map_container: Node
@export var _car_container: Node
@export var _pause_menu: PauseMenu

var _current_map: Map = null

func start_map(map_index: int) -> void:
	if _current_map != null:
		_current_map.queue_free()
		_current_map = null
	var map: Map = MAPS[map_index].instantiate()
	_map_container.add_child(map)
	_current_map = map
	temp_delete_me_later()

func _ready() -> void:
	_pause_menu.set_visible(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_pause_menu.resume_pressed.connect(_on_pause_menu_resume_pressed)
	_pause_menu.leave_pressed.connect(_on_pause_menu_leave_pressed)
	if get_multiplayer().is_server():
		_pause_menu.lobby_pressed.connect(_on_pause_menu_lobby_pressed)

func temp_delete_me_later() -> void:
	_current_map.get_camera().clear_current()
	var car: VehicleBody3D = preload("res://entities/car/car.scn").instantiate()
	_car_container.add_child(car)
	car.set_transform(_current_map.get_team_1_spawners_transform()[0])

func _process(_delta: float):
	if Input.is_action_just_pressed("ui_close_dialog"):
		_pause_menu.set_visible(not _pause_menu.is_visible())
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if _pause_menu.is_visible() else Input.MOUSE_MODE_CAPTURED)

func _on_pause_menu_resume_pressed() -> void:
	_pause_menu.set_visible(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_pause_menu_lobby_pressed() -> void:
	back_to_lobby_requested.emit()

func _on_pause_menu_leave_pressed() -> void:
	get_multiplayer().get_multiplayer_peer().close()
	get_multiplayer().set_multiplayer_peer(OfflineMultiplayerPeer.new())
	get_tree().change_scene_to_file("res://scenes/main-menu/main-menu.scn")
