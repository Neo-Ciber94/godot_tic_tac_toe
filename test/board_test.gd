extends Node

@onready var board: Board = $Board;

func _ready():
	board.prepare_board();
	board.fill_slots(" ", Color.TRANSPARENT);
	
	board.on_hover.connect(func(slot, idx, is_over):
		print("hover: ", { idx = idx, is_over = is_over })
	)
	
	board.on_click.connect(func(_slot, idx): 
		print("clicked: ", idx);
		board.set_slot_value(idx, "x", Color.WHITE)	
	)
