class_name CarController extends Node

# Vehicle references.
@export var vehicle: VehicleBody3D
@export var mesh: MeshInstance3D

# Optional: leave empty to auto-detect the VehicleWheel3D children of the vehicle.
# Only wheels with "use_as_traction" enabled are treated as driven wheels.
@export var wheels: Array[VehicleWheel3D] = []

# Engine settings.
@export var max_engine_force: float = 6000.0
@export var reverse_engine_force: float = 3200.0
@export var idle_rpm: float = 800.0
@export var peak_torque_rpm: float = 4400.0
@export var redline_rpm: float = 6200.0

# Engine response settings.
@export var engine_acceleration: float = 2500.0
@export var engine_deceleration: float = 3500.0
@export var engine_braking: float = 2000.0
# How fast the clutch re-engages after a shift (1 / seconds).
@export var clutch_response: float = 5.0
# How fast the engine revs when nothing is holding it back (neutral, wheels in the air, stuck).
@export var free_rev_acceleration: float = 6000.0
# RPM the engine can reach while launching from a stop (clutch / torque converter slip).
@export var launch_rpm: float = 2200.0

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
@export var reverse_speed_limit: float = 5.5

# Automatic transmission settings.
@export var shift_up_rpm: float = 5400.0
@export var shift_down_rpm: float = 2200.0
@export var shift_delay: float = 0.4
@export var kickdown_throttle: float = 0.85
# The automatic gearbox holds the current gear while slip is above this value.
@export var slip_gear_hold: float = 0.25

# Wheel spin settings.
# How fast the driven wheels speed up / slow down while slipping.
@export var wheel_spin_response: float = 6.0
# How fast the driven wheels re-sync with the ground when grip returns.
@export var wheel_grip_response: float = 25.0
# Rotate the wheel meshes with the "virtual" wheel speed (needs a Node3D child on each driven wheel).
@export var spin_wheel_visuals: bool = true

# "Stuck" detection: throttle pressed, in gear, but the car is not moving.
@export var stuck_speed: float = 0.8
@export var stuck_delay: float = 0.35
# How much the wheels spin (0..1) once the car is considered stuck.
@export var stuck_wheelspin: float = 0.7

# Brake settings.
@export var max_brake_force: float = 95.0

# Steering settings.
@export var max_steering_angle: float = 0.3
@export var steering_speed: float = 1.1
# The max steering angle shrinks as speed increases, which keeps the car stable.
# Speed (m/s) at which the reduction is complete, and the fraction of max_steering_angle left.
@export var steering_reduction_speed: float = 30.0
@export var min_steering_factor: float = 0.3

# Engine sound settings.
# A looping AudioStreamPlayer3D (change the type if you use a plain AudioStreamPlayer).
@export var engine_audio: AudioStreamPlayer3D
# RPM at which the loop sample was recorded (pitch_scale = 1.0).
@export var audio_reference_rpm: float = 1800.0
# Volume off throttle / at full throttle.
@export var audio_min_volume_db: float = -20.0
@export var audio_max_volume_db: float = -18.0
@export var audio_volume_response: float = 6.0

# Gear values:
# -1 = Reverse
#  0 = Neutral
#  1+ = Drive gears
@export var current_gear: int = 1 :
	set(value):
		current_gear = value
		_update_gear_label()

@export var is_braking: bool = false :
	set(value):
		is_braking = value
		var mat: StandardMaterial3D = mesh.get_mesh().surface_get_material(2)
		mat.emission_enabled = is_braking

const SLIP_SMOOTHING: float = 10.0

var current_steering: float = 0.0
@export
var engine_rpm: float = 800.0
var shift_timer: float = 0.0

# Drivetrain state.
# 0 = clutch open (no torque), 1 = fully engaged.
var clutch: float = 1.0
# Virtual rpm of the driven wheels. Positive = rolling forward.
# Matches the ground speed when there is grip, but can differ when there is not.
var wheel_rpm: float = 0.0
# 0 = full grip, 1 = no traction at all (wheels in the air, ice, stuck...).
var drive_slip: float = 0.0
var stuck_timer: float = 0.0

# Driven wheels and their visuals (all arrays share the same index).
var _driven_wheels: Array[VehicleWheel3D] = []
var _wheel_visuals: Array[Node3D] = []
var _visual_rest_basis: Array[Basis] = []
# Estimate of how fast Godot itself is rotating each wheel.
var _physics_wheel_rpm: PackedFloat32Array = PackedFloat32Array()
# Extra rotation we add on top of Godot's wheel rotation.
var _visual_spin_angle: PackedFloat32Array = PackedFloat32Array()

@export
var throttle_input: float = 0.0

var _game_match: GameMatch = null

func set_game_match(game_match: GameMatch) -> void:
	_game_match = game_match

func _ready() -> void:
	_setup_wheels()

func _physics_process(delta: float) -> void:
	if vehicle == null:
		return
	
	if not is_multiplayer_authority():
		_update_engine_sound(throttle_input, delta)
		return
	
	# Read the vehicle's forward speed.
	var forward_speed: float = vehicle.linear_velocity.dot(
		-vehicle.global_basis.z
	)
	var speed: float = absf(forward_speed)

	# Rpm the wheels would have if they were rolling on the ground (signed).
	var ground_rpm: float = (
		forward_speed / wheel_radius * 60.0 / (2.0 * PI)
	)

	# Read inputs.
	var brake_input: float
	var steering_input: float
	
	if _game_match != null and not _game_match.is_paused():
		throttle_input = Input.get_action_strength("accelerate")
		brake_input = Input.get_action_strength("brake")
		steering_input = Input.get_axis(
			"steer_right",
			"steer_left"
		)
	else:
		throttle_input = 0.0
	
	is_braking = brake_input != 0.0
	
	# Toggle between Drive and Reverse.
	_handle_drive_input(speed)

	# Drivetrain: traction -> wheels -> engine -> transmission.
	clutch = move_toward(clutch, 1.0, clutch_response * delta)

	_update_drive_slip(speed, throttle_input, brake_input, delta)
	_update_wheel_rpm(ground_rpm, throttle_input, brake_input, delta)
	_update_engine_rpm(throttle_input, delta)
	_handle_automatic_transmission(delta, throttle_input)

	# Apply engine force and brakes.
	_apply_engine(throttle_input)
	vehicle.brake = brake_input * max_brake_force

	# Smooth steering. The steering angle shrinks as speed increases.
	var steering_limit: float = lerpf(
		max_steering_angle,
		max_steering_angle * min_steering_factor,
		clampf(speed / steering_reduction_speed, 0.0, 1.0)
	)

	var target_steering: float = steering_input * steering_limit

	current_steering = move_toward(
		current_steering,
		target_steering,
		steering_speed * delta
	)

	vehicle.steering = current_steering

	# Wheel visuals and sound.
	_update_wheel_visuals(ground_rpm, delta)
	_update_engine_sound(throttle_input, delta)

	# Update dashboard.
	_update_gear_label()

	$"../Label".text = "%.0f km/h | %.0f RPM" % [
		vehicle.linear_velocity.length() * 3.6,
		engine_rpm
	]


func _setup_wheels() -> void:
	if vehicle == null:
		return

	var found: Array[VehicleWheel3D] = []

	for wheel in wheels:
		found.append(wheel)

	if found.is_empty():
		for child in vehicle.get_children():
			if child is VehicleWheel3D:
				found.append(child)

	for wheel in found:
		if not wheel.use_as_traction:
			continue

		var visual: Node3D = _find_wheel_visual(wheel)

		_driven_wheels.append(wheel)
		_wheel_visuals.append(visual)
		_visual_rest_basis.append(
			visual.basis if visual != null else Basis.IDENTITY
		)
		_physics_wheel_rpm.append(0.0)
		_visual_spin_angle.append(0.0)


func _find_wheel_visual(wheel: VehicleWheel3D) -> Node3D:
	# Uses the first Node3D child of the wheel (usually its MeshInstance3D).
	for child in wheel.get_children():
		if child is Node3D:
			return child

	return null


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

	_begin_shift()


func _begin_shift() -> void:
	shift_timer = shift_delay
	# Opening the clutch cuts the torque for a moment.
	clutch = 0.0


func _get_gear_direction() -> float:
	if current_gear == -1:
		return -1.0

	return 1.0


func _get_total_ratio() -> float:
	# Total reduction between engine and wheels. 0 in neutral.
	if current_gear == -1:
		return reverse_ratio * final_drive_ratio

	if current_gear >= 1 and current_gear <= gear_ratios.size():
		return gear_ratios[current_gear - 1] * final_drive_ratio

	return 0.0


func _update_drive_slip(
	speed: float,
	throttle: float,
	brake_input: float,
	delta: float
) -> void:
	var slip: float = 0.0

	# Wheels in the air or skidding have no traction.
	if not _driven_wheels.is_empty():
		for wheel in _driven_wheels:
			if wheel.is_in_contact():
				slip += 1.0 - wheel.get_skidinfo()
			else:
				slip += 1.0

		slip /= float(_driven_wheels.size())

	# Stuck: the driver is asking for power, the car is in gear,
	# but it is not going anywhere (mud, high-centered, against a wall...).
	var trying_to_move: bool = (
		throttle > 0.5
		and brake_input < 0.1
		and clutch >= 1.0
		and _get_total_ratio() > 0.0
	)

	if trying_to_move and speed < stuck_speed:
		stuck_timer += delta
	else:
		stuck_timer = 0.0

	if stuck_timer > stuck_delay:
		slip = maxf(slip, stuck_wheelspin)

	# Smooth it, contact / skid info can be noisy from frame to frame.
	drive_slip = lerpf(
		drive_slip,
		clampf(slip, 0.0, 1.0),
		1.0 - exp(-SLIP_SMOOTHING * delta)
	)


func _update_wheel_rpm(
	ground_rpm: float,
	throttle: float,
	brake_input: float,
	delta: float
) -> void:
	var ratio: float = _get_total_ratio()

	# What the wheels do when the ground does NOT hold them.
	var free_wheel_rpm: float

	if ratio > 0.0 and throttle > 0.01 and clutch > 0.5:
		# The engine drags the wheels along.
		free_wheel_rpm = engine_rpm / ratio * _get_gear_direction()
	elif brake_input > 0.01:
		# Brakes locking the wheels.
		free_wheel_rpm = 0.0
	else:
		# Nothing pushes or stops them, they slowly lose speed.
		free_wheel_rpm = wheel_rpm * pow(0.99, delta * 60.0)

	# Full grip: wheels follow the ground. No grip: wheels follow the engine.
	var target_rpm: float = lerpf(ground_rpm, free_wheel_rpm, drive_slip)
	var response: float = lerpf(
		wheel_grip_response,
		wheel_spin_response,
		drive_slip
	)

	wheel_rpm = lerpf(
		wheel_rpm,
		target_rpm,
		1.0 - exp(-response * delta)
	)

	# Close enough with grip: lock to the ground exactly.
	if drive_slip < 0.01 and absf(wheel_rpm - ground_rpm) < 20.0:
		wheel_rpm = ground_rpm


func _update_engine_rpm(throttle: float, delta: float) -> void:
	var ratio: float = _get_total_ratio()

	# What the engine does when nothing holds it back.
	var free_rpm: float = lerpf(idle_rpm, redline_rpm, throttle)

	var target_rpm: float = free_rpm
	# 1 = engine is completely unloaded (revs freely).
	var unloaded: float = 1.0

	if ratio > 0.0:
		# What the wheels force on the engine when they are connected.
		var coupled_rpm: float = absf(wheel_rpm) * ratio

		# Launching: the clutch / torque converter slips,
		# so the engine can rev above what the wheels ask for.
		if absi(current_gear) == 1:
			coupled_rpm = maxf(
				coupled_rpm,
				lerpf(idle_rpm, launch_rpm, throttle)
			)

		# Less traction means less load on the engine.
		unloaded = drive_slip
		target_rpm = lerpf(coupled_rpm, free_rpm, drive_slip)

	target_rpm = clampf(target_rpm, idle_rpm, redline_rpm)

	# Smooth the engine response.
	var response: float = engine_deceleration

	if target_rpm > engine_rpm:
		response = lerpf(
			engine_acceleration,
			free_rev_acceleration,
			unloaded
		)
	elif throttle <= 0.01:
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

	# While the wheels slip, engine rpm no longer says anything about
	# the car's speed, so keep the current gear.
	if drive_slip > slip_gear_hold:
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
			_begin_shift()
			return

	# Upshift near the target RPM.
	if engine_rpm >= shift_up_rpm:
		if current_gear < gear_count:
			current_gear += 1
			_begin_shift()
			return

	# Downshift when RPM is low.
	if engine_rpm <= shift_down_rpm:
		if current_gear > 1:
			current_gear -= 1
			_begin_shift()


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
	# Neutral.
	if current_gear == 0:
		vehicle.engine_force = 0.0
		return

	# Reverse.
	if current_gear == -1:
		vehicle.engine_force = (
			-throttle *
			reverse_engine_force *
			_get_torque_factor() *
			clutch
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
		_get_torque_factor() *
		clutch
	)


func _update_wheel_visuals(ground_rpm: float, delta: float) -> void:
	for i in _driven_wheels.size():
		var wheel: VehicleWheel3D = _driven_wheels[i]

		# Estimate how fast VehicleBody3D is rotating this wheel by itself:
		# it follows the ground speed, and fades out when in the air.
		if wheel.is_in_contact():
			_physics_wheel_rpm[i] = ground_rpm
		else:
			_physics_wheel_rpm[i] *= pow(0.99, delta * 60.0)

		if not spin_wheel_visuals:
			continue

		var visual: Node3D = _wheel_visuals[i]

		if visual == null:
			continue

		# Whatever the physics rotation is missing is added to the mesh.
		var extra_rpm: float = wheel_rpm - _physics_wheel_rpm[i]
		var extra_angle: float = extra_rpm * TAU / 60.0 * delta

		_visual_spin_angle[i] = fposmod(
			_visual_spin_angle[i] + extra_angle,
			TAU
		)

		# Rolling forward is a NEGATIVE rotation around the wheel's X axle.
		# If the wheels spin the wrong way, remove the minus sign here.
		visual.basis = (
			Basis(Vector3.RIGHT, -_visual_spin_angle[i]) *
			_visual_rest_basis[i]
		)


func _update_engine_sound(throttle: float, delta: float) -> void:
	if engine_audio == null:
		return

	# The sample must have looping enabled in its import settings.
	if not engine_audio.playing:
		engine_audio.play()

	# Pitch follows the engine rpm.
	engine_audio.pitch_scale = clampf(
		engine_rpm / audio_reference_rpm,
		0.1,
		4.0
	)

	# Volume follows throttle (mostly) and rpm.
	var rpm_factor: float = inverse_lerp(
		idle_rpm,
		redline_rpm,
		engine_rpm
	)
	var loudness: float = clampf(
		throttle * 0.7 + rpm_factor * 0.3,
		0.0,
		1.0
	)
	var target_db: float = lerpf(
		audio_min_volume_db,
		audio_max_volume_db,
		loudness
	)

	engine_audio.volume_db = lerpf(
		engine_audio.volume_db,
		target_db,
		1.0 - exp(-audio_volume_response * delta)
	)


func _update_gear_label() -> void:
	var mat: StandardMaterial3D = mesh.get_mesh().surface_get_material(3)
	if current_gear == -1:
		mat.emission_enabled = true
	else:
		mat.emission_enabled = false
