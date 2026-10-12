class_name CarController extends Node

# Vehicle references.
@export var vehicle: VehicleBody3D
@export var reverse_light: MeshInstance3D
@export var brake_light: MeshInstance3D

# Engine settings.
@export var max_engine_force: float = 6000.0
@export var reverse_engine_force: float = 2000.0
@export var idle_rpm: float = 800.0
@export var peak_torque_rpm: float = 4400.0
@export var redline_rpm: float = 6200.0

# Engine response settings.
@export var engine_acceleration: float = 2500.0
@export var engine_deceleration: float = 3500.0
@export var engine_braking: float = 1800.0
@export var clutch_response: float = 5.0

# Transmission settings.
@export var gear_ratios: Array[float] = [
	3.6,
	2.19,
	1.41,
	1.0,
	0.83
]
@export var reverse_ratio: float = 3.0
@export var final_drive_ratio: float = 3.27
@export var drivetrain_efficiency: float = 0.85
@export var wheel_radius: float = 0.364
@export var reverse_speed_limit: float = 4.0

# Automatic transmission settings.
@export var shift_up_rpm: float = 5400.0
@export var shift_down_rpm: float = 2200.0
@export var shift_delay: float = 0.4
@export var kickdown_throttle: float = 0.85

# Brake settings.
@export var max_brake_force: float = 60.0

# Steering settings.
@export var max_steering_angle: float = 0.45
@export var steering_speed: float = 1.5

# Gear values:
# -1 = Reverse
#  1+ = Drive gears
@export var current_gear: int = 1 :
	set(value):
		current_gear = value
		_update_gear_label()

@export var is_braking: bool = false :
	set(value):
		is_braking = value
		var mat: StandardMaterial3D = brake_light.get_active_material(0) as StandardMaterial3D
		mat.emission_enabled = is_braking

var current_steering: float = 0.0
var engine_rpm: float = 800.0
var shift_timer: float = 0.0

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if vehicle == null:
		return

	# Read the vehicle's forward speed.
	var forward_speed: float = vehicle.linear_velocity.dot(
		-vehicle.global_basis.z
	)
	var speed: float = absf(forward_speed)

	# Read inputs.
	var throttle: float = Input.get_action_strength("accelerate")
	var brake_input: float = Input.get_action_strength("brake")
	
	is_braking = brake_input != 0.0

	var steering_input: float = Input.get_axis(
		"steer_right",
        "steer_left"
	)

	# Toggle between Drive and Reverse.
	_handle_drive_input(speed)

	# Update engine RPM and automatic transmission.
	_update_engine_rpm(speed, throttle, delta)
	_handle_automatic_transmission(delta, throttle)
	_update_engine_rpm(speed, throttle, delta)

	# Apply engine force and brakes.
	_apply_engine(throttle)
	vehicle.brake = brake_input * max_brake_force

	# Smooth steering.
	var target_steering: float = (
		steering_input * max_steering_angle
	)

	current_steering = move_toward(
		current_steering,
		target_steering,
		steering_speed * delta
	)

	vehicle.steering = current_steering

	# Update dashboard.
	_update_gear_label()

	$"../Label".text = "%.0f km/h | %.0f RPM" % [
		vehicle.linear_velocity.length() * 3.6,
		engine_rpm
	]


func _handle_drive_input(speed: float) -> void:
	if not Input.is_action_just_pressed("gear_reverse"):
		return

	# Only allow switching direction near a stop.
	if speed >= reverse_speed_limit:
		return

	if current_gear == -1:
		current_gear = 1
	else:
		current_gear = -1

	shift_timer = shift_delay


func _update_engine_rpm(
	speed: float,
	throttle: float,
	delta: float
) -> void:
	var target_rpm: float = idle_rpm

	# Calculate wheel RPM from vehicle speed.
	var wheel_rpm: float = (
		speed / wheel_radius * 60.0 / (2.0 * PI)
	)

	if current_gear > 0 and not gear_ratios.is_empty():
		var gear_index: int = current_gear - 1
		var ratio: float = gear_ratios[gear_index]

		target_rpm = maxf(
			idle_rpm,
			wheel_rpm * ratio * final_drive_ratio
		)

	elif current_gear == -1:
		target_rpm = maxf(
			idle_rpm,
			wheel_rpm * reverse_ratio * final_drive_ratio
		)

	else:
		# Engine revs independently in neutral.
		target_rpm = lerpf(
			idle_rpm,
			peak_torque_rpm,
			throttle
		)

	target_rpm = minf(target_rpm, redline_rpm)

	# Smooth the engine response.
	var response: float = engine_deceleration

	if target_rpm > engine_rpm:
		response = engine_acceleration

	if throttle <= 0.01 and target_rpm < engine_rpm:
		response = engine_braking

	engine_rpm = move_toward(
		engine_rpm,
		target_rpm,
		response * delta
	)

	engine_rpm = clampf(
		engine_rpm,
		idle_rpm,
		redline_rpm
	)


func _handle_automatic_transmission(
	delta: float,
	throttle: float
) -> void:
	shift_timer = maxf(shift_timer - delta, 0.0)

	# Reverse is selected manually.
	if current_gear == -1:
		return

	if shift_timer > 0.0:
		return

	var gear_count: int = gear_ratios.size()

	if gear_count == 0:
		return

	# Kickdown: downshift for stronger acceleration.
	if throttle >= kickdown_throttle and current_gear > 1:
		var lower_gear_index: int = current_gear - 2
		var current_gear_index: int = current_gear - 1

		var next_lower_rpm: float = (
			engine_rpm *
			gear_ratios[lower_gear_index] /
			gear_ratios[current_gear_index]
		)

		if next_lower_rpm < redline_rpm:
			current_gear -= 1
			shift_timer = shift_delay
			return

	# Upshift near the target RPM.
	if engine_rpm >= shift_up_rpm:
		if current_gear < gear_count:
			current_gear += 1
			shift_timer = shift_delay
			return

	# Downshift when RPM is low.
	if engine_rpm <= shift_down_rpm:
		if current_gear > 1:
			current_gear -= 1
			shift_timer = shift_delay


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
	# Reverse.
	if current_gear == -1:
		vehicle.engine_force = (
			-throttle *
			reverse_engine_force *
			_get_torque_factor()
		)
		return

	if gear_ratios.is_empty():
		vehicle.engine_force = 0.0
		return

	# Apply the selected forward gear ratio.
	var gear_index: int = current_gear - 1
	var ratio: float = gear_ratios[gear_index]
	var first_ratio: float = gear_ratios[0]

	var gear_multiplier: float = ratio / first_ratio

	vehicle.engine_force = (
		throttle *
		max_engine_force *
		gear_multiplier *
		_get_torque_factor()
	)


func _update_gear_label() -> void:
	var mat: StandardMaterial3D = reverse_light.get_active_material(0) as StandardMaterial3D
	if current_gear == -1:
		mat.emission_enabled = true
	else:
		mat.emission_enabled = false
