class_name HumanPlayer;
extends Player;

var _board: Board;

func _init(board: Board):
	_board = board;
	
func next_move(board_state: Array[String]):
	_board.on_click.connect(func(_slot, idx): on_move.emit(idx), Object.CONNECT_ONE_SHOT)

func _to_string() -> String:
	return "HumanPlayer"
