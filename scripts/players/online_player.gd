extends Player;

class_name OnlinePlayer;

var peer_id: int;

func _init(peer_id: int):
	self.peer_id = peer_id;

func next_move(cells: Array[Cell], board: Array[String]):
	for idx in range(0, cells.size()):
		var cell = cells[idx]
		cell.on_click.connect(func(_args):
			on_move.emit(idx)	
		)
