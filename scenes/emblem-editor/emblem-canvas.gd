class_name EmblemCanvas extends Control

const CANVAS_SIZE: Vector2i = Vector2i(128, 128)
const BACKGROUND_COLOR: Color = Color.WHITE
const MIN_BRUSH_SIZE: float = 1.0
const MAX_BRUSH_SIZE: float = 16.0

var brush_color: Color = Color.BLACK
var brush_size: float = 2.0

var is_drawing: bool = false
var strokes: Array[Dictionary] = []
var current_stroke: Dictionary = {}


func create_canvas_image() -> Image:
	var image: Image = Image.create(
		CANVAS_SIZE.x,
		CANVAS_SIZE.y,
		false,
		Image.FORMAT_RGBA8
	)
	image.fill(BACKGROUND_COLOR)

	for stroke: Dictionary in strokes:
		_draw_stroke_to_image(image, stroke)

	return image


func _draw_stroke_to_image(image: Image, stroke: Dictionary) -> void:
	var points: PackedVector2Array = stroke["points"]
	var color: Color = stroke["color"]
	var width: float = stroke["size"]

	if points.is_empty():
		return

	if points.size() == 1:
		_stamp_segment(image, points[0], points[0], width, color)
		return

	for i: int in range(points.size() - 1):
		_stamp_segment(
			image,
			points[i],
			points[i + 1],
			width,
			color
		)


func _stamp_segment(
	image: Image,
	start: Vector2,
	end: Vector2,
	width: float,
	color: Color
) -> void:
	var radius: float = width * 0.5
	var min_x: int = maxi(0, floori(minf(start.x, end.x) - radius))
	var max_x: int = mini(CANVAS_SIZE.x - 1, ceili(maxf(start.x, end.x) + radius))
	var min_y: int = maxi(0, floori(minf(start.y, end.y) - radius))
	var max_y: int = mini(CANVAS_SIZE.y - 1, ceili(maxf(start.y, end.y) + radius))

	var segment: Vector2 = end - start
	var segment_length_squared: float = segment.length_squared()

	for y: int in range(min_y, max_y + 1):
		for x: int in range(min_x, max_x + 1):
			var pixel_center: Vector2 = Vector2(x + 0.5, y + 0.5)
			var t: float = 0.0

			if segment_length_squared > 0.0:
				t = clampf(
					(pixel_center - start).dot(segment) / segment_length_squared,
					0.0,
					1.0
				)

			var closest_point: Vector2 = start + segment * t

			if pixel_center.distance_to(closest_point) <= radius:
				image.set_pixel(x, y, color)

func _ready() -> void:
	custom_minimum_size = Vector2(CANVAS_SIZE)
	size = Vector2(CANVAS_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event

		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return

		if mouse_event.pressed:
			_start_stroke(mouse_event.position)
		else:
			_finish_stroke()

	elif event is InputEventMouseMotion and is_drawing:
		var mouse_event: InputEventMouseMotion = event
		_add_point(mouse_event.position)


func _start_stroke(pos: Vector2) -> void:
	is_drawing = true

	current_stroke = {
		"points": PackedVector2Array([
			_to_canvas_position(pos)
		]),
		"color": brush_color,
		"size": brush_size
	}

	queue_redraw()


func _add_point(pos: Vector2) -> void:
	var points: PackedVector2Array = current_stroke["points"]
	var canvas_position: Vector2 = _to_canvas_position(pos)

	if points[-1].distance_to(canvas_position) < 0.25:
		return

	points.append(canvas_position)
	current_stroke["points"] = points

	queue_redraw()


func _finish_stroke() -> void:
	if not is_drawing:
		return

	is_drawing = false

	if not current_stroke.is_empty():
		strokes.append(current_stroke)

	current_stroke = {}
	queue_redraw()


func _to_canvas_position(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, 0.0, float(CANVAS_SIZE.x)),
		clampf(pos.y, 0.0, float(CANVAS_SIZE.y))
	)


func _draw() -> void:
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(CANVAS_SIZE)),
		BACKGROUND_COLOR
	)

	for stroke: Dictionary in strokes:
		_draw_stroke(stroke)

	if not current_stroke.is_empty():
		_draw_stroke(current_stroke)


func _draw_stroke(stroke: Dictionary) -> void:
	var points: PackedVector2Array = stroke["points"]
	var color: Color = stroke["color"]
	var width: float = stroke["size"]

	if points.is_empty():
		return

	if points.size() == 1:
		draw_circle(points[0], width * 0.5, color)
		return

	draw_polyline(points, color, width, true)

	draw_circle(points[0], width * 0.5, color)
	draw_circle(points[-1], width * 0.5, color)


func set_brush_color(new_color: Color) -> void:
	brush_color = new_color


func set_brush_size(new_size: float) -> void:
	brush_size = clampf(
		new_size,
		MIN_BRUSH_SIZE,
		MAX_BRUSH_SIZE
	)


func clear_canvas() -> void:
	is_drawing = false
	strokes.clear()
	current_stroke = {}
	queue_redraw()
