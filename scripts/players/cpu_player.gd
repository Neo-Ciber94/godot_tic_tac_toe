extends Player;

class_name CpuPlayer;

enum PlayStyle {
	RANDOM,
	MIN,
	MAX
}

var _play_style: PlayStyle;
var _value: String;

func _init(value: String, play_style = PlayStyle.RANDOM) -> void:
	_play_style = play_style;
	_value = value;

func next_move(cells: Array[Cell], board: Array[String]):
	print("waiting for cpu move")
	await get_tree().create_timer(0.5).timeout
	
	var index = _next_move(board);
	print("cpu move to: ", index)
	on_move.emit(index)

func _next_move(board: Array[String]):
	match _play_style:
		PlayStyle.RANDOM:
			return _get_next_random(board);
		PlayStyle.MIN:
			pass
		PlayStyle.MAX:
			pass
			
func _get_next_random(board: Array[String]) -> int:
	var indices : Array[int] = [];
	
	for idx in board.size():
		var value = board[idx];
		
		if value == Game.EMPTY:
			indices.push_back(idx);
	
	return indices.pick_random()

const WIN_POSITIONS : Array = [
		# verticals
		[0, 1, 2],
		[3, 4, 5],
		[6, 7, 8],

		# horizontals
		[0, 3, 6],
		[1, 4, 7],
		[2, 5, 8],
		
		# diagonals
		[0, 4, 8],
		[2, 4, 6]
	];
	
func _get_play():
	pass

func _minimax():
	
	
	pass
