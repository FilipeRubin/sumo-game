extends VBoxContainer

@export var _main_menu: MainMenu

@export var _join_button: Button
@export var _back_button: Button
@export var _address_line: LineEdit
@export var _port_line: LineEdit
@export var _first_screen: VBoxContainer

func _ready() -> void:
	_join_button.pressed.connect(_on_join_button_pressed)
	_back_button.pressed.connect(_on_back_button_pressed)

func _on_join_button_pressed() -> void:
	var address: String = _address_line.get_text()
	var port: int = _port_line.get_text().to_int()
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	if peer.create_client(address, port) == OK:
		get_multiplayer().set_multiplayer_peer(peer)

func _on_back_button_pressed() -> void:
	_main_menu.set_visible_screen(_first_screen)
