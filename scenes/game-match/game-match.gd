class_name GameMatch extends Node

signal back_to_lobby_requested()

const MAPS: Array[PackedScene] = [
	preload("res://maps/map0/map0.scn"),
	preload("res://maps/map1/map1.scn"),
	preload("res://maps/map2/map2.scn")
]

const SAFE_AREA: PackedScene = preload("res://entities/safe-area/safe-area.scn")

@export var _map_container: Node
@export var _car_container: Node
@export var _safe_area_container: Node
@export var _map_spawner: MultiplayerSpawner
@export var _pause_menu: PauseMenu
@export var _match_hud: MatchHUD
@export var _safe_timer: Timer
@export var _camera: DynamicCamera

var _current_map: Map = null
var _current_safe_area: SafeArea = null
var _spectator_mode: bool = true
var _spectating_car: int = 0

func start_map(map_index: int) -> void:
	if _current_map != null:
		_current_map.queue_free()
		_current_map = null
	var map: Map = MAPS[map_index].instantiate()
	_map_container.add_child(map)
	_current_map = map
	_spawn_cars_for_all_players()

func _ready() -> void:
	_map_spawner.spawned.connect(_on_map_spawned)
	_pause_menu.set_visible(false)
	_match_hud.set_visible(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_pause_menu.resume_pressed.connect(_on_pause_menu_resume_pressed)
	_pause_menu.leave_pressed.connect(_on_pause_menu_leave_pressed)
	if get_multiplayer().is_server():
		_pause_menu.lobby_pressed.connect(_on_pause_menu_lobby_pressed)
		get_multiplayer().peer_disconnected.connect(_on_peer_disconnected)
		_safe_timer.timeout.connect(_on_safe_timer_timeout)
		await get_tree().create_timer(10.0).timeout
		_create_random_safe_area()

func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _spawn_cars_for_all_players() -> void:
	var id_array: Array = get_multiplayer().get_peers()
	id_array.append(get_multiplayer().get_unique_id())
	id_array.shuffle()
	var team1_max_index: int = id_array.size() / 2
	for i: int in range(id_array.size()):
		var car: Car = preload("res://entities/car/car.scn").instantiate()
		if i < team1_max_index:
			car.set_transform(_current_map.get_team_1_spawners_transform()[i])
			car.team = 1
		else:
			car.set_transform(_current_map.get_team_2_spawners_transform()[i - team1_max_index])
			car.team = 2
		_car_container.add_child(car, true)
		_set_car_authority.rpc(car.get_name(), id_array[i])

func _process(_delta: float):
	if Input.is_action_just_pressed("ui_close_dialog"):
		_pause_menu.set_visible(not _pause_menu.is_visible())
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if _pause_menu.is_visible() else Input.MOUSE_MODE_CAPTURED)
	_match_hud.set_visible(not _pause_menu.is_visible())
	_match_hud.set_progress(_safe_timer.get_time_left())
	
	if _spectator_mode and _car_container.get_child_count() > 0:
		if Input.is_action_just_pressed("steer_right"):
			_spectating_car += 1
			if _spectating_car > (_car_container.get_child_count() - 1):
				_spectating_car = 0
			_camera.attach_to(_car_container.get_child(_spectating_car))
		elif Input.is_action_just_pressed("steer_left"):
			_spectating_car -= 1
			if _spectating_car < 0:
				_spectating_car = _car_container.get_child_count() - 1
			_camera.attach_to(_car_container.get_child(_spectating_car))

func _on_map_spawned(node: Node) -> void:
	var map: Map = node
	_camera.attach_to(map.get_camera_target())

func _on_peer_disconnected(id: int) -> void:
	for car: Car in _car_container.get_children():
		if car.get_multiplayer_authority() == id:
			car.queue_free()

func _on_pause_menu_resume_pressed() -> void:
	_pause_menu.set_visible(false)
	_match_hud.set_visible(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_pause_menu_lobby_pressed() -> void:
	back_to_lobby_requested.emit()

func _on_pause_menu_leave_pressed() -> void:
	get_multiplayer().get_multiplayer_peer().close()
	get_multiplayer().set_multiplayer_peer(OfflineMultiplayerPeer.new())
	get_tree().change_scene_to_file("res://scenes/main-menu/main-menu.scn")

func _kill_unsafe_cars() -> void:
	var safe_cars_ids: Array[int] = _current_safe_area.get_safe_cars_ids()
	for car: Car in _car_container.get_children():
		if car.get_multiplayer_authority() not in safe_cars_ids:
			car.destroy_car()

func _check_winner() -> int:
	if _car_container.get_children().size() == 0:
		return 0
	var last_team_checked: int = -1
	for car: Car in _car_container.get_children():
		if last_team_checked == -1:
			last_team_checked = car.team
			continue
		if last_team_checked != car.team:
			return -1
	return last_team_checked

func _create_random_safe_area() -> void:
	_start_safe_timer_for_all.rpc()
	for i: Node in _safe_area_container.get_children():
		i.queue_free()
	var safe_area: SafeArea = SAFE_AREA.instantiate()
	var t: Transform3D = _current_map.get_safe_areas().pick_random()
	safe_area.set_transform(t)
	_safe_area_container.add_child(safe_area, true)
	_current_safe_area = safe_area

func _on_safe_timer_timeout() -> void:
	_kill_unsafe_cars()
	await get_tree().create_timer(1.0).timeout
	var winner: int = _check_winner()
	if winner == -1:
		_create_random_safe_area()
	else:
		_set_winning_text.rpc(winner)

func _on_my_car_destroyed() -> void:
	_spectator_mode = true
	if _car_container.get_child_count() > 0:
		_camera.attach_to(_car_container.get_child(0) as Node3D)

@rpc("authority", "call_local", "reliable")
func _set_car_authority(car_name: String, id: int) -> void:
	var car: Car = _car_container.get_node_or_null(car_name)
	if car == null:
		push_warning("Car not found!")
	car.set_multiplayer_authority(id)
	if car.is_multiplayer_authority():
		_spectator_mode = false
		car.control_car()
		car.my_car_destroyed.connect(_on_my_car_destroyed)
		_camera.attach_to(car)
		car.player_name = Globals.player_name

@rpc("authority", "call_local", "reliable")
func _start_safe_timer_for_all() -> void:
	_safe_timer.start()

@rpc("authority", "call_local", "reliable")
func _set_winning_text(winner: int) -> void:
	if winner == 0:
		_match_hud.set_winning_text("It's a draw!", Color.WHITE)
	elif winner == 1:
		_match_hud.set_winning_text("Team 1 wins!", Color.DARK_ORCHID)
	elif winner == 2:
		_match_hud.set_winning_text("Team 2 wins!", Color.GOLDENROD)
