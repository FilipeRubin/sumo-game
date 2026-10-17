class_name SafeArea extends Area3D

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _collider: CollisionShape3D = $CollisionShape3D

func set_safe_area_radius(radius: float) -> void:
	_set_safe_area_radius_remote.rpc(radius)

func get_safe_cars_ids() -> Array[int]:
	var result: Array[int] = []
	for node: Node3D in get_overlapping_bodies():
		if node is Car:
			result.append(node.get_multiplayer_authority())
	return result

@rpc("authority", "call_local", "reliable")
func _set_safe_area_radius_remote(radius: float) -> void:
	var mesh: SphereMesh = _mesh.get_mesh()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var shape: SphereShape3D = _collider.get_shape()
	shape.radius = radius
