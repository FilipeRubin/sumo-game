class_name Map extends Node3D

@export var _camera_target: Marker3D
@export var _team_1_spawners_root: Node
@export var _team_2_spawners_root: Node
@export var _safe_areas_root: Node

func get_camera_target() -> Marker3D:
	return _camera_target

func get_team_1_spawners_transform() -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for i: Marker3D in _team_1_spawners_root.get_children():
		result.append(i.get_transform())
	return result

func get_team_2_spawners_transform() -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for i: Marker3D in _team_2_spawners_root.get_children():
		result.append(i.get_transform())
	return result

func get_safe_areas() -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for i: Marker3D in _safe_areas_root.get_children():
		result.append(i.get_transform())
	return result

func _ready() -> void:
	if is_multiplayer_authority():
		_shuffle_children(_team_1_spawners_root)
		_shuffle_children(_team_2_spawners_root)

func _shuffle_children(container: Node) -> void:
	var children: Array[Node] = container.get_children()
	children.shuffle()
	for i in range(children.size()):
		container.move_child(children[i], i)
