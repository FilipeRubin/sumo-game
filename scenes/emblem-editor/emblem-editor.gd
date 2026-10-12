extends Control

@export var canvas: EmblemCanvas
@export var color_picker: ColorPickerButton
@export var brush_slider: HSlider
@export var clear_button: Button
@export var save_button: Button
@export var back_button: Button

func _ready() -> void:
	brush_slider.min_value = 1.0
	brush_slider.max_value = 16.0
	brush_slider.step = 1.0
	brush_slider.value = canvas.brush_size

	color_picker.color = canvas.brush_color

	color_picker.color_changed.connect(_on_color_changed)
	brush_slider.value_changed.connect(_on_brush_size_changed)
	clear_button.pressed.connect(_on_clear_pressed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main-menu/main-menu.scn")

func _on_color_changed(new_color: Color) -> void:
	canvas.set_brush_color(new_color)

func _on_save_pressed() -> void:
	Globals.saved_emblem = canvas.create_canvas_image().save_png_to_buffer()

func _on_brush_size_changed(new_size: float) -> void:
	canvas.set_brush_size(new_size)


func _on_clear_pressed() -> void:
	canvas.clear_canvas()
