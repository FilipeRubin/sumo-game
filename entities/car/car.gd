class_name Car extends VehicleBody3D

signal my_car_destroyed()

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
		$MuscleCar.get_mesh().surface_set_material(0, mat)

@export
var player_name: String :
	set(value):
		player_name = value
		$PlayerLabel.set_text(player_name)

@export
var emblem_bytes: PackedByteArray :
	set(value):
		emblem_bytes = value
		if emblem_bytes.size() == 0:
			return
		var emblem_image: Image = Image.new()
		emblem_image.load_png_from_buffer(emblem_bytes)
		var emblem_texture: Texture2D = ImageTexture.create_from_image(emblem_image)
		$Emblem.texture_albedo = emblem_texture

var _recently_collided: Array[Car] = []

@onready var _game_match: GameMatch = get_parent().get_parent() as GameMatch

func control_car() -> void:
	$Label.set_visible(true)
	$PlayerLabel.set_visible(false)
	$IndicatorController.set_process(true)
	$CarController.set_game_match(_game_match)
	$IndicatorController.set_game_match(_game_match)
	body_entered.connect(_on_body_entered)

func destroy_car() -> void:
	_destroy_car_remote.rpc()

func _ready() -> void:
	get_multiplayer().peer_connected.connect(_on_peer_connected)

func _on_peer_connected(id: int) -> void:
	_send_authority.rpc_id(id, get_multiplayer_authority())

func _on_body_entered(body: Node) -> void:
	if body is Car and body not in _recently_collided:
		linear_velocity += body.linear_velocity * 0.55
		_recently_collided.append(body)
		await get_tree().create_timer(0.4).timeout
		_recently_collided.erase(body)

@rpc("authority", "call_remote", "reliable")
func _send_authority(id: int) -> void:
	set_multiplayer_authority(id)

@rpc("any_peer", "call_local", "reliable")
func _destroy_car_remote() -> void:
	if get_multiplayer_authority() == get_multiplayer().get_unique_id():
		my_car_destroyed.emit()
	set_multiplayer_authority(1)
	if get_multiplayer().is_server():
		queue_free()
