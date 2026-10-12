class_name HostScreen extends VBoxContainer

signal created_server()

@export var _main_menu: MainMenu

@export var _host_button: Button
@export var _back_button: Button
@export var _port_line: LineEdit
@export var _first_screen: VBoxContainer

func _ready() -> void:
	_host_button.pressed.connect(_on_host_button_pressed)
	_back_button.pressed.connect(_on_back_button_pressed)

func _on_host_button_pressed() -> void:
	var port: int = _port_line.get_text().to_int()
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	if peer.create_server(port, 23) == OK:
		get_multiplayer().set_multiplayer_peer(peer)
		created_server.emit()

func _on_back_button_pressed() -> void:
	_main_menu.set_visible_screen(_first_screen)
