extends Control

@export var game: Game;
var label: Label;
var index: int;

const COLOR_UNSET = Color(0,0,0,0.5);
const COLOR_MARK_X = Color.RED;
const COLOR_MARK_O = Color.BLUE;

func _ready() -> void:
	game.start_game.connect(_on_start_game)
	
func _on_start_game():
	label = get_child(0)
	index = name.get_slice("Mark", 1).to_int() - 1
	
	mouse_entered.connect(is_hovered.bind(true))
	mouse_exited.connect(is_hovered.bind(false))
	set_text_color(game.PLACEHOLDER, COLOR_UNSET)
	
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		on_click()

func is_hovered(is_over: bool):	
	if game.has_value(index) || game.is_finished():
		return;
		
	if is_over:
		set_text_color(game.PLACEHOLDER, get_mark_color(), 0.5)
	else:
		set_text_color(game.PLACEHOLDER, COLOR_UNSET)

func on_click():
	if game.has_value(index) || game.is_finished():
		return;
		
	set_text_color(game.get_turn_player(), get_mark_color(), 0.5)
	game.set_value(index)

func get_mark_color():
	if game.get_turn_player() == game.MARK_X:
		return COLOR_MARK_X
	else:
		return COLOR_MARK_O

func set_text_color(text: String, color: Color, alpha: float= -1.0):
	if alpha > 0.0:
		color.a = alpha;
	
	label.text = text;
	label.add_theme_color_override("font_color", color);
	
