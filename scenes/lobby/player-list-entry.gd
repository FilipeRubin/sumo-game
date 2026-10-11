class_name PlayerListEntry extends HBoxContainer

@onready var _name_label: Label = $Name

func set_player_name(player_name: String) -> void:
	_name_label.set_text(player_name)

func get_player_name() -> String:
	return _name_label.get_text()
