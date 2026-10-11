extends VBoxContainer

@export var _main_menu: MainMenu

@export var _name_line: LineEdit
@export var _host_button: Button
@export var _join_button: Button
@export var _join_screen: VBoxContainer
@export var _host_screen: VBoxContainer

func _ready() -> void:
	_name_line.text_changed.connect(_on_name_line_text_changed)
	_host_button.pressed.connect(_on_host_button_pressed)
	_join_button.pressed.connect(_on_join_button_pressed)
	_host_button.set_disabled(_name_line.get_text().length() == 0)
	_join_button.set_disabled(_name_line.get_text().length() == 0)

func _on_name_line_text_changed(new_text: String) -> void:
	_host_button.set_disabled(new_text.length() == 0)
	_join_button.set_disabled(new_text.length() == 0)
	Globals.player_name = new_text

func _on_host_button_pressed() -> void:
	_main_menu.set_visible_screen(_host_screen)

func _on_join_button_pressed() -> void:
	_main_menu.set_visible_screen(_join_screen)
