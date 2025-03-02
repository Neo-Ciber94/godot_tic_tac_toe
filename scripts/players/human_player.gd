extends Player;

class_name HumanPlayer;
	
func next_move(cells: Array[Cell], _board: Array[String]):
	for idx in range(0, cells.size()):
		var cell = cells[idx]
		cell.on_click.connect(func(_args):
			on_move.emit(idx)	
		)
		
