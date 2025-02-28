extends Player;

class_name HumanPlayer;
	
func player_move(cells: Array[Cell]):
	for idx in range(0, cells.size()):
		var cell = cells[idx]
		cell.on_click.connect(func(_args):
			on_move.emit(idx)	
		)
		
