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

class MessageBuilder:
	var msg_display: MessageDisplay;
	var position: Position = Position.CENTER;
	var size: Size = Size.LARGE;
	var effect: Effect = Effect.NONE;
	
	func _init(message_display: MessageDisplay):
		msg_display = message_display;
		
	func with_position(new_pos: Position) -> MessageBuilder:
		self.position = new_pos;
		return self;

	func with_size(new_size: Size) -> MessageBuilder:
		self.size = new_size;
		return self;
		
	func with_effect(new_effect: Effect) -> MessageBuilder:
		self.effect = new_effect;
		return self;
		
	func show_message(msg: String, color: Color = Color.BLACK) -> void:
		msg_display.show_message(
			msg,
			color,
			position,
			size,
			effect
		)
	
signal on_click;

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		on_click.emit()
		

func with_effect(new_effect: Effect) -> MessageBuilder:
	return MessageBuilder.new(self).with_effect(new_effect)
	
func with_position(new_pos: Position) -> MessageBuilder:
	return MessageBuilder.new(self).with_position(new_pos)
	
func with_size(new_size: Size) -> MessageBuilder:
	return MessageBuilder.new(self).with_size(new_size)

func show_message(msg: String, color: Color = Color.BLACK, position: Position = Position.CENTER, size: Size = Size.LARGE, effect = Effect.NONE):
	match position:
		Position.CENTER:
			vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		Position.TOP:
			vertical_alignment = VERTICAL_ALIGNMENT_TOP
		Position.BOTTOM:
			vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		
	clear()
	add_theme_font_size_override("normal_font_size", size)
	push_color(color);
	
	match effect:
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
