extends Player;

class_name OnlinePlayer;

var peer_id: int;
var move_rpc: Callable;

func _init(peer_id: int, move_rpc: Callable):
	self.peer_id = peer_id;
	self.move_rpc = move_rpc;

func next_move(cells: Array[Cell], board: Array[String]):
	for idx in range(0, cells.size()):
		var cell = cells[idx]
		cell.on_click.connect(func(_args):
			move_rpc.call(idx)	
		)
