class_name CpuPlayer;
extends Player;

enum Difficulty {
	EASY,
	NORMAL,
	HARD,
	IMPOSSIBLE
}

var _difficulty: Difficulty;
var _my_player: String;
var _opp_player: String;

func _init(my_player: String, opp_player: String, difficulty = Difficulty.EASY) -> void:
	_difficulty = difficulty;
	_my_player = my_player;
	_opp_player = opp_player;

func next_move(game_state: Array[String]):
	Logger.debug("waiting for cpu move")
	await get_tree().create_timer(0.5).timeout
	
	var index = _next_move(game_state);
	Logger.debug("cpu move to: ", index)
	on_move.emit(index)

func _next_move(board: Array[String]):
	match _difficulty:
		Difficulty.EASY:
			return _get_next_random(board);
		Difficulty.NORMAL:
			return _next_move_with_probability(0.2, 1, board);
		Difficulty.HARD:
			return _next_move_with_probability(0.4, 3, board);
		Difficulty.IMPOSSIBLE:
			return _find_best_move(board.duplicate(), INF);
				

func _next_move_with_probability(probability: float, depth: int, board: Array[String]):
		if _rand_bool(probability):
			return _find_best_move(board.duplicate(), depth)
		else:
			return _get_next_random(board)
			
func _get_next_random(board: Array[String]) -> int:
	var indices : Array[int] = [];
	
	for idx in board.size():
		var value = board[idx];
		
		if value == Constants.EMPTY:
			indices.push_back(idx);
	
	return indices.pick_random()

func _find_best_move(board: Array[String], depth: int) -> int:
	assert(!_is_board_full(board), "board is full");

	var best_move = -1;
	var best_score = -1000;
	var alpha = -1000
	var beta = 1000
	
	for idx in board.size():
		if board[idx] != Constants.EMPTY:
			continue;
			
		Logger.debug("Evaluating move for index: ", idx)
		board[idx] = _my_player;
		var score = _minimax(board, depth, false, alpha, beta);
		board[idx] = Constants.EMPTY;
		
		Logger.debug("Score for move: ", { idx = idx, score = score });
		if score > best_score:
			best_score = score;
			best_move = idx;
	
	if best_move == -1:
		Logger.warn("failed to find best move for CPU, this its a bug");
		return _find_empty_index(board);
	
	return best_move;

func _minimax(board: Array[String], depth: int, is_max: bool, alpha: int, beta: int) -> int:
	if _is_board_full(board) || depth == 0:
		return _evaluate(board);
	
	var best_score = -1000 if is_max else 1000;
	
	if is_max:
		for idx in board.size():
			if board[idx] != Constants.EMPTY:
				continue;
				
			board[idx] = _my_player;
			var score = _minimax(board, depth - 1, !is_max, alpha, beta);
			board[idx] = Constants.EMPTY;
			best_score = max(score, best_score);
			alpha = max(alpha, best_score);
			
			if beta <= alpha:
				break
				
		return best_score;
	else:
		for idx in board.size():
			if board[idx] != Constants.EMPTY:
				continue;
				
			board[idx] = _opp_player;
			var score = _minimax(board, depth - 1, !is_max, alpha, beta);
			board[idx] = Constants.EMPTY;
			best_score = min(score, best_score);
			beta = min(beta, best_score);
			
			if beta <= alpha:
				break
	
	return best_score;
	
func _evaluate(board: Array[String]) -> int:
	var win_indices = Utils.WIN_POSITIONS;
	
	for idx in win_indices.size():
		var indices : Array[int] = [];
		indices.assign(win_indices[idx]);
		var values = Utils.select_indices(board, indices)		
		
		if values.all(func(x): return x == _my_player):
			return 10;
			
		if values.all(func(x): return x == _opp_player):
			return -10;
	
	return 0;

func _is_board_full(board: Array[String]) -> bool:
	return !board.has(Constants.EMPTY)
	
func _find_empty_index(board: Array[String]):
	for idx in board.size():
		if board[idx] == Constants.EMPTY:
			return idx;
			
	return -1;

func _rand_bool(probability: float) -> bool:
	return randf() <= probability;

func _to_string() -> String:
	var name = Difficulty.find_key(_difficulty)
	return "CpuPlayer(%s, %s)" % [name, _my_player]
