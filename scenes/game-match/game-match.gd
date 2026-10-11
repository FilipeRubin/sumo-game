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
	_spawn_cars_for_all_players()

func _ready() -> void:
	_pause_menu.set_visible(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_pause_menu.resume_pressed.connect(_on_pause_menu_resume_pressed)
	_pause_menu.leave_pressed.connect(_on_pause_menu_leave_pressed)
	if get_multiplayer().is_server():
		_pause_menu.lobby_pressed.connect(_on_pause_menu_lobby_pressed)
		get_multiplayer().peer_disconnected.connect(_on_peer_disconnected)

func _spawn_cars_for_all_players() -> void:
	var id_array: Array = get_multiplayer().get_peers()
	id_array.append(get_multiplayer().get_unique_id())
	id_array.shuffle()
	var team1_max_index: int = id_array.size() / 2
	for i: int in range(id_array.size()):
		var car: Car = preload("res://entities/car/car.scn").instantiate()
		if i < team1_max_index:
			car.set_transform(_current_map.get_team_1_spawners_transform()[i])
		else:
			car.set_transform(_current_map.get_team_2_spawners_transform()[i - team1_max_index])
		_car_container.add_child(car, true)
		_set_car_authority.rpc(car.get_name(), id_array[i], i < team1_max_index)

func _process(_delta: float):
	if Input.is_action_just_pressed("ui_close_dialog"):
		_pause_menu.set_visible(not _pause_menu.is_visible())
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if _pause_menu.is_visible() else Input.MOUSE_MODE_CAPTURED)

func _on_peer_disconnected(id: int) -> void:
	for car: Car in _car_container.get_children():
		if car.get_multiplayer_authority() == id:
			car.queue_free()

func _on_pause_menu_resume_pressed() -> void:
	_pause_menu.set_visible(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_pause_menu_lobby_pressed() -> void:
	back_to_lobby_requested.emit()

func _on_pause_menu_leave_pressed() -> void:
	get_multiplayer().get_multiplayer_peer().close()
	get_multiplayer().set_multiplayer_peer(OfflineMultiplayerPeer.new())
	get_tree().change_scene_to_file("res://scenes/main-menu/main-menu.scn")

@rpc("authority", "call_local", "reliable")
func _set_car_authority(car_name: String, id: int, team: int) -> void:
	var car: Car = _car_container.get_node_or_null(car_name)
	if car == null:
		push_warning("Car not found!")
	car.team = team
	car.set_multiplayer_authority(id)
	if car.is_multiplayer_authority():
		car.control_car()
