extends Control

class_name Cell;

var label: Label;
signal on_click(Cell);
signal on_hover(Cell, bool);

func _ready():
	label = get_node("Label");
	
	mouse_entered.connect(func(): 
		on_hover.emit(self, true)
	)
	
	mouse_exited.connect(func(): 
		on_hover.emit(self, false)
	)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		on_click.emit(self)
				
func draw_mark(mark: String, color: Color):
	label.text = mark;
	label.add_theme_color_override("font_color", color);

func get_mark():
	return label.text;
	
func is_set():
	return get_mark() != Constants.PLACEHOLDER;
