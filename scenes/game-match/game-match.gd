class_name GameMatch extends Node

const MAPS: Array[PackedScene] = [
	preload("res://maps/map0/map0.scn")
]

@export var _map_container: Node

func start_map(map_index: int) -> void:
	_map_container.add_child(MAPS[map_index].instantiate())
