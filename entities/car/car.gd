class_name Car extends VehicleBody3D

@export
var team: int :
	set(value):
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		if value == 1:
			mat.albedo_color = Color.DARK_ORCHID
		else:
			mat.albedo_color = Color.GOLDENROD
		$MeshInstance3D.get_mesh().surface_set_material(0, mat)

func _ready() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	if team == 1:
		mat.albedo_color = Color.DARK_ORCHID
	else:
		mat.albedo_color = Color.GOLDENROD
	$MeshInstance3D.get_mesh().surface_set_material(0, mat)
	print(team)

func control_car() -> void:
	$CarController.set_physics_process(true)
	$CameraBoom/Camera3D.make_current()
	$Label.set_visible(true)
