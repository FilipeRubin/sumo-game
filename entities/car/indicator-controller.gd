class_name IndicatorController extends Node

enum TurnSignalMode {
	OFF,
	LEFT,
	RIGHT,
	HAZARD
}

@export var mesh: MeshInstance3D
@export var indicator_timer: Timer

@export var indicator_multiplayer: int = 0 :
	set(value):
		indicator_multiplayer = value
		indicator = value as TurnSignalMode

var indicator: TurnSignalMode = TurnSignalMode.OFF :
	set(value):
		indicator = value
		if indicator != TurnSignalMode.OFF:
			var first_start: bool = indicator_timer.is_stopped()
			var left_mat: StandardMaterial3D = mesh.get_mesh().surface_get_material(4)
			var right_mat: StandardMaterial3D = mesh.get_mesh().surface_get_material(5)
			if first_start:
				indicator_timer.start()
				match indicator:
					TurnSignalMode.LEFT:
						left_mat.emission_enabled = true
						right_mat.emission_enabled = false
					TurnSignalMode.RIGHT:
						left_mat.emission_enabled = false
						right_mat.emission_enabled = true
					TurnSignalMode.HAZARD:
						left_mat.emission_enabled = true
						right_mat.emission_enabled = true

func _ready() -> void:
	set_process(false)
	indicator_timer.timeout.connect(_on_indicator_timer_timeout)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("turn_signal_left"):
		if indicator == TurnSignalMode.LEFT:
			indicator_multiplayer = TurnSignalMode.OFF
		else:
			indicator_multiplayer = TurnSignalMode.LEFT
	if Input.is_action_just_pressed("turn_signal_right"):
		if indicator == TurnSignalMode.RIGHT:
			indicator_multiplayer = TurnSignalMode.OFF
		else:
			indicator_multiplayer = TurnSignalMode.RIGHT
	if Input.is_action_just_pressed("turn_signal_hazard"):
		if indicator == TurnSignalMode.HAZARD:
			indicator_multiplayer = TurnSignalMode.OFF
		else:
			indicator_multiplayer = TurnSignalMode.HAZARD

func _on_indicator_timer_timeout() -> void:
	var left_mat: StandardMaterial3D = mesh.get_mesh().surface_get_material(4)
	var right_mat: StandardMaterial3D = mesh.get_mesh().surface_get_material(5)
	if indicator == TurnSignalMode.OFF:
		left_mat.emission_enabled = false
		right_mat.emission_enabled = false
		return
	indicator_timer.start()
	match indicator:
		TurnSignalMode.LEFT:
			left_mat.emission_enabled = not left_mat.emission_enabled
			right_mat.emission_enabled = false
		TurnSignalMode.RIGHT:
			left_mat.emission_enabled = false
			right_mat.emission_enabled = not right_mat.emission_enabled
		TurnSignalMode.HAZARD:
			left_mat.emission_enabled = not left_mat.emission_enabled
			right_mat.emission_enabled = left_mat.emission_enabled
