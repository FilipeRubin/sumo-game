class_name Car extends VehicleBody3D

func control_car() -> void:
	$CarController.set_physics_process(true)
	$CameraBoom/Camera3D.make_current()
