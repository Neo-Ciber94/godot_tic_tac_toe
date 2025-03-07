extends Player;

class_name OnlinePlayer;

var peer_id: int;
var move_rpc: Callable;
var _board: Board;

func _init(board: Board, peer_id: int, move_rpc: Callable):
	self._board = board;
	self.peer_id = peer_id;
	self.move_rpc = move_rpc;

func next_move(board_state: Array[String]):
	_board.on_click.connect(func(_this, idx): move_rpc.call(idx), Object.CONNECT_ONE_SHOT)
		

func _to_string() -> String:
	return "OnlinePlayer(%s)" % peer_id
