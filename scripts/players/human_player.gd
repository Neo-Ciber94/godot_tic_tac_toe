extends Player;

class_name HumanPlayer;
	
func next_move(board: Board, state: Array[String]):
	board.on_click.connect(func(_slot, idx): on_move.emit(idx), Object.CONNECT_ONE_SHOT)
