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
				
func draw_mark(mark: String, color: Color, animate = false):
	label.text = mark;
	label.add_theme_color_override("font_color", color);
	
	if animate:
		var duration = 0.2;
		var tween = get_tree().create_tween()
		label.modulate = Color(color, 0.5);
		label.scale = Vector2(1, 1);
	
		tween.tween_property(label, "modulate", Color(color, 1), duration);
		tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), duration);
		tween.tween_property(label, "scale", Vector2(1, 1), duration);
		await tween.finished;

func get_mark():
	return label.text;
