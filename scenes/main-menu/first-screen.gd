extends VBoxContainer

@export var _main_menu: MainMenu

@export var _host_button: Button
@export var _join_button: Button
@export var _join_screen: VBoxContainer
@export var _host_screen: VBoxContainer

func _ready() -> void:
	_host_button.pressed.connect(_on_host_button_pressed)
	_join_button.pressed.connect(_on_join_button_pressed)

func _on_host_button_pressed() -> void:
	_main_menu.set_visible_screen(_host_screen)

func _on_join_button_pressed() -> void:
	_main_menu.set_visible_screen(_join_screen)
