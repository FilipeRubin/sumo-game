class_name DeathArea extends Area3D

func _ready() -> void:
	collision_mask = 2
	if get_multiplayer().is_server():
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Car:
		body.destroy_car()
