extends Player;

class_name OnlinePlayer;

var peer_id: int;
var move_rpc: Callable;
var _board: Board;

func _init(peer_id: int, move_rpc: Callable):
	self.peer_id = peer_id;
	self.move_rpc = move_rpc;

func set_board(board: Board):
	_board = board;

func next_move(board_state: Array[String]):
	assert(_board, "online player board was not set");
	_board.on_click.connect(func(_this, idx): move_rpc.call(idx), Object.CONNECT_ONE_SHOT)
		
func _to_string() -> String:
	return "OnlinePlayer(%s)" % peer_id
