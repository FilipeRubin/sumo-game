class_name PauseMenu extends Control

signal resume_pressed()
signal lobby_pressed()
signal leave_pressed()

@export var _resume_button: Button
@export var _lobby_button: Button
@export var _leave_button: Button

func _ready() -> void:
	_lobby_button.set_visible(get_multiplayer().is_server())
	_resume_button.pressed.connect(_on_resume_pressed)
	_lobby_button.pressed.connect(_on_lobby_pressed)
	_leave_button.pressed.connect(_on_leave_pressed)

func _on_resume_pressed() -> void:
	resume_pressed.emit()

func _on_lobby_pressed() -> void:
	lobby_pressed.emit()

func _on_leave_pressed() -> void:
	leave_pressed.emit()
