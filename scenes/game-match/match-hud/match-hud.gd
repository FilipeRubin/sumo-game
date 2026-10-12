class_name MatchHUD extends Control

func set_progress(value: float) -> void:
	$ProgressBar.set_value(value)

func set_winning_text(text: String, color: Color) -> void:
	$ProgressBar.set_visible(false)
	$WinningText.set_visible(true)
	$WinningText.set_text(text)
	$WinningText.add_theme_color_override("font_color", color)
