extends Player;

class_name CpuPlayer;

enum Difficulty {
	RANDOM,
	EASY,
	HARD,
	IMPOSSIBLE
}

var _difficulty: Difficulty;
var _value: String;

func _init(value: String, difficulty = Difficulty.RANDOM) -> void:
	_difficulty = difficulty;
	_value = value;

func next_move(_board: Board, state: Array[String]):
	print("waiting for cpu move")
	await get_tree().create_timer(0.5).timeout
	
	var index = _next_move(state);
	print("cpu move to: ", index)
	on_move.emit(index)

func _next_move(board: Array[String]):
	match _difficulty:
		Difficulty.RANDOM:
			return _get_next_random(board);
		Difficulty.EASY:
			return _find_next_move(board, false)
		Difficulty.HARD:
			return _find_next_move(board, true)
		Difficulty.IMPOSSIBLE:
			var my_result = _minimax(board, _value, true)
			var opp_result = _minimax(board, Game.get_opponent(_value), true);
			
			if my_result.best_eval > opp_result.best_eval:
				return my_result.best_index;
			else:
				return opp_result.best_index;
			
func _get_next_random(board: Array[String]) -> int:
	var indices : Array[int] = [];
	
	for idx in board.size():
		var value = board[idx];
		
		if value == Game.EMPTY:
			indices.push_back(idx);
	
	return indices.pick_random()

func _find_next_move(board: Array[String], is_max: bool) -> int:
	# If the board is empty we can start anywhere.
	if (board.all(func(x): return x == Game.EMPTY)):
		return range(0, board.size).pick_random()
	
	var result = _minimax(board, _value, is_max);
	return result.best_index;

func _minimax(board: Array[String], player_value: String, is_max: bool):	
	var win_positions = Utils.WIN_POSITIONS;
	var best_index = -1;
	var best_eval = -1000 if is_max else 1000;
	var valid_values = [player_value, Game.EMPTY];
	
	for idx in win_positions.size():
		var indices : Array[int] = [];
		indices.assign(win_positions[idx]);
		var board_values = Utils.select_indices(board, indices)

		# the best win position its the one that contains the value of this player, in order:
		# [x, x, ~], [x, ~, ~] [~, ~, ~]
		var opp_value = board_values.filter(func(x): return !valid_values.has(x)).size();
		var my_value = board_values.count(player_value);
		var evaluation = my_value - opp_value;
			
		if is_max:			
			if evaluation > best_eval:
				best_eval = evaluation;
				best_index = _find_empty_index(board, indices);			
		else:
			if evaluation < best_eval:
				best_eval = evaluation
				best_index = _find_empty_index(board, indices);
	
	# Set a fallback value
	if best_index == -1:
		best_index = board.find(Game.EMPTY)
		
	return {
		best_index = best_index,
		best_eval = best_eval
	}

func _find_empty_index(board: Array, indices: Array[int]):
	for board_idx in indices:
		var value = board[board_idx];
		
		if value == Game.EMPTY:
			return board_idx;
			
	return -1;
