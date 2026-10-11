
class_name CarController extends Node

@export var vehicle: VehicleBody3D
@export var gear_label: Label3D

# Engine settings.
@export var max_engine_force: float = 6000.0
@export var reverse_engine_force: float = 2000.0
@export var idle_rpm: float = 800.0
@export var peak_torque_rpm: float = 4400.0
@export var redline_rpm: float = 6200.0

# Transmission settings.
@export var gear_ratios: Array[float] = [
	3.2,
	2.1,
	1.5,
	1.1,
	0.85
]
@export var reverse_ratio: float = 3.0
@export var final_drive_ratio: float = 3.27
@export var drivetrain_efficiency: float = 0.85
@export var wheel_radius: float = 0.364
@export var reverse_speed_limit: float = 1.5

# Brake settings.
@export var max_brake_force: float = 60.0

# Steering settings.
@export var max_steering_angle: float = 0.45
@export var steering_speed: float = 1.5

var current_gear: int = 1
var current_steering: float = 0.0
var engine_rpm: float = 800.0


func _physics_process(delta: float) -> void:
	if vehicle == null:
		return

	var forward_speed: float = vehicle.linear_velocity.dot(
		-vehicle.global_basis.z
	)

	_handle_gear_input(absf(forward_speed))

	var throttle: float = Input.get_action_strength("accelerate")
	var brake_input: float = Input.get_action_strength("brake")

	var steering_input: float = Input.get_axis(
		"steer_right",
        "steer_left"
	)

	_update_engine_rpm(absf(forward_speed), throttle)
	_apply_engine(throttle)

	vehicle.brake = brake_input * max_brake_force

	var target_steering: float = (
		steering_input * max_steering_angle
	)

	current_steering = move_toward(
		current_steering,
		target_steering,
		steering_speed * delta
	)

	vehicle.steering = current_steering

	$"../Label".text = "%.0f km/h | %.0f RPM" % [
		vehicle.linear_velocity.length() * 3.6,
		engine_rpm
	]


func _update_engine_rpm(speed: float, throttle: float) -> void:
	# Calculate engine RPM from wheel speed and gear ratios.
	if current_gear > 0 and gear_ratios.size() > 0:
		var gear_index: int = current_gear - 1
		var ratio: float = gear_ratios[gear_index]

		var wheel_rpm: float = (
			speed / wheel_radius * 60.0 / (2.0 * PI)
		)

		engine_rpm = maxf(
			idle_rpm,
			wheel_rpm * ratio * final_drive_ratio
		)

	elif current_gear == -1:
		var wheel_rpm: float = (
			speed / wheel_radius * 60.0 / (2.0 * PI)
		)

		engine_rpm = maxf(
			idle_rpm,
			wheel_rpm * reverse_ratio * final_drive_ratio
		)

	else:
		# Let the engine rev while the transmission is in neutral.
		engine_rpm = lerpf(
			idle_rpm,
			peak_torque_rpm,
			throttle
		)

	engine_rpm = minf(engine_rpm, redline_rpm)


func _get_torque_factor() -> float:
	# Approximate the engine torque curve.
	var low_rpm_factor: float = lerpf(
		0.65,
		1.0,
		clampf(
			(engine_rpm - idle_rpm) /
			(peak_torque_rpm - idle_rpm),
			0.0,
			1.0
		)
	)

	var high_rpm_factor: float = clampf(
		(redline_rpm - engine_rpm) /
		(redline_rpm - peak_torque_rpm),
		0.0,
		1.0
	)

	return minf(low_rpm_factor, high_rpm_factor)


func _apply_engine(throttle: float) -> void:
	if current_gear == 0:
		vehicle.engine_force = 0.0
		return

	var torque_factor: float = _get_torque_factor()

	if current_gear == -1:
		vehicle.engine_force = (
			-throttle *
			reverse_engine_force *
			torque_factor
		)
		return

	if gear_ratios.is_empty():
		vehicle.engine_force = 0.0
		return

	var gear_index: int = current_gear - 1
	var ratio: float = gear_ratios[gear_index]
	var first_ratio: float = gear_ratios[0]

	# Higher gears provide less wheel force but allow more speed.
	var gear_multiplier: float = ratio / first_ratio

	vehicle.engine_force = (
		throttle *
		max_engine_force *
		gear_multiplier *
		torque_factor
	)


func _handle_gear_input(speed: float) -> void:
	if Input.is_action_just_pressed("gear_up"):
		if current_gear < 0:
			current_gear = 0
		elif current_gear < gear_ratios.size():
			current_gear += 1

	if Input.is_action_just_pressed("gear_down"):
		if current_gear > 1:
			current_gear -= 1
		elif current_gear == 1:
			current_gear = 0

	if Input.is_action_just_pressed("gear_reverse"):
		if speed < reverse_speed_limit:
			if current_gear == -1:
				current_gear = 0
			else:
				current_gear = -1

	_update_gear_label()


func _update_gear_label() -> void:
	if gear_label == null:
		return

	if current_gear == -1:
		gear_label.text = "R"
	elif current_gear == 0:
		gear_label.text = "N"
	else:
		gear_label.text = str(current_gear)
