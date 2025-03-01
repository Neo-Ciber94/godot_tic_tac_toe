extends CenterContainer;
class_name Dialog;

@onready var label = $Label;

signal on_click;

func change_text(msg: String, color: Color):
	label.text = msg;
	label.add_theme_color_override("font_color", color)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		on_click.emit()
	
