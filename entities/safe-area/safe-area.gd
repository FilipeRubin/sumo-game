class_name SafeArea extends Area3D

func get_safe_cars_ids() -> Array[int]:
	var result: Array[int] = []
	for node: Node3D in get_overlapping_bodies():
		if node is Car:
			result.append(node.get_multiplayer_authority())
	return result
