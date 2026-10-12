class_name Car extends VehicleBody3D

@export
var team: int :
	set(value):
		team = value
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		if team == 1:
			mat.albedo_color = Color.DARK_ORCHID
			$PlayerLabel.set_modulate(Color.DARK_ORCHID)
		else:
			mat.albedo_color = Color.GOLDENROD
			$PlayerLabel.set_modulate(Color.GOLDENROD)
		$MeshInstance3D.get_mesh().surface_set_material(0, mat)
		$MeshInstance3D2.get_mesh().surface_set_material(0, mat)

@export
var player_name: String :
	set(value):
		player_name = value
		$PlayerLabel.set_text(player_name)

func control_car() -> void:
	$CarController.set_physics_process(true)
	$CameraBoom/Camera3D.make_current()
	$Label.set_visible(true)
	$PlayerLabel.set_visible(false)

func destroy_car() -> void:
	_destroy_car_remote.rpc()

@rpc("any_peer", "call_local", "reliable")
func _destroy_car_remote() -> void:
	set_multiplayer_authority(1)
	if get_multiplayer().is_server():
		queue_free()
