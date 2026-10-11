class_name Map extends Node3D

@export var _camera: Camera3D
@export var _team_1_spawners_root: Node
@export var _team_2_spawners_root: Node
@export var _safe_areas_root: Node

func get_camera() -> Camera3D:
	return _camera

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
