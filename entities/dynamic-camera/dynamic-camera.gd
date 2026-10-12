class_name DynamicCamera extends SpringArm3D

var _target: Node3D

func attach_to(new_target: Node3D) -> void:
	_target = new_target if is_instance_valid(new_target) else null

	if is_instance_valid(_target):
		global_position = _target.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * Globals.mouse_sensitivity
		rotation.x -= event.relative.y * Globals.mouse_sensitivity
		rotation.x = clampf(
			rotation.x,
			deg_to_rad(-80.0),
			deg_to_rad(80.0)
		)

func _process(_delta: float) -> void:
	if not is_instance_valid(_target) or not _target.is_inside_tree():
		_target = null
		return

	# Follow the target instantly, without smoothing.
	global_position = _target.global_position
