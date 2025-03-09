class_name MessageDisplay;
extends RichTextLabel;

enum Position {
	CENTER,
	TOP,
	BOTTOM
}

enum Size {
	SMALL = 25,
	MEDIUM = 50,
	LARGE = 100
}

enum Effect {
	NONE,
	SHAKE,
	WAVE,
	PULSE,
	FADE,
	RAINBOW
}

signal on_click;

var _position: Position = Position.CENTER;
var _size: Size = Size.LARGE;
var _effect : Effect = Effect.NONE;
var _is_clickable: bool = true;

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		on_click.emit()
		
func set_message_position(new_pos: Position):
	_position = new_pos;
			
func set_message_size(new_size: Size):
	_size = new_size;
	
func set_message_effect(new_effect: Effect):
	_effect = new_effect;
	
func set_can_click(is_clickable: bool):
	_is_clickable = is_clickable;

func show_message(msg: String, color: Color = Color.BLACK):		
	clear()
	add_theme_font_size_override("normal_font_size", _size)
	push_color(color);
	
	match _position:
		Position.CENTER:
			vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		Position.TOP:
			vertical_alignment = VERTICAL_ALIGNMENT_TOP
		Position.BOTTOM:
			vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			
	match _effect:
		Effect.NONE:
			append_text(msg)
		Effect.SHAKE:
			append_text("[shake]" + msg + "[/shake]")
		Effect.WAVE:
			append_text("[wave]" + msg + "[/wave]")
		Effect.PULSE:
			append_text("[pulse]" + msg + "[/pulse]")
		Effect.FADE:
			append_text("[fade]" + msg + "[/fade]")
		Effect.RAINBOW:
			append_text("[rainbow]" + msg + "[/rainbow]")
	
	if _is_clickable:
		mouse_filter = Control.MOUSE_FILTER_STOP;
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE;
		
	_reset_message()

func _reset_message():
	_position = Position.CENTER;
	_size = Size.LARGE;
	_effect = Effect.NONE;
	_is_clickable = true;
