class_name Match;
extends Node

var _board: Array[String] = []
var _players: Dictionary[String, Player] = {};
var _current_player: String;

signal on_player_move(player: Player, value: String, index: int);
signal on_game_over(winner: Winner);
signal on_game_start(players: Dictionary[String, Player], current_player: String);
signal on_switch_turns(player: Player, value: String);
signal on_waiting();

func _ready():
	reset_board()

func reset_board() -> void:
	_board = []
	
	for idx in range(9):
		_board.push_back(Constants.EMPTY);
			
func add_players(players: Dictionary[String, Player]) -> void:
	var player_values = players.keys();
	assert(player_values.size() == 2, "expected 2 players");
	assert(player_values[0] != player_values[1], "players should be different");
	
	_players = players;
	set_current_player(_players.keys().pick_random());
	
	# add the players to the tree
	for player in _players.values():
		add_child(player)
	
func set_current_player(value: String):
	_current_player = value;
	
func start_match() -> void:
	assert(_players.size() == 2, "expected 2 players to start the match");
		
	on_game_start.emit(_players, _current_player);
	
	while(true):
		var player = _players[_current_player];
		var index = await _request_next_move(player);
		
		if !_is_valid_move(index):
			continue;
		
		_board[index] = _current_player;
		on_player_move.emit(player, _current_player, index);
		var winner = Utils.check_winner(_board, Constants.EMPTY);
		
		if winner.is_finished():
			_declare_winner(winner);
			break;
		else:
			print("switch players")
			_switch_players();
	
func get_turn_player() -> Player:
	return _players[_current_player];

func get_current_player():
	return _current_player;
	
func get_players() -> Dictionary[String, Player]:
	return _players.duplicate()
	
func has_value(index: int) -> bool:
	return _board[index] != Constants.EMPTY;
		
func get_board_state() -> Array[String]:
	return _board.duplicate();

func _is_valid_move(index: int) -> bool:	
	if _board[index] == Constants.EMPTY:
		return true;
	
	print("invalid move: ", { 
		index = index, 
		player = _players[_current_player], 
		current_player = _current_player 
	})
			
	return false;
	
func _request_next_move(player: Player) -> int:
	var index = { value = -1 }
	
	var callable = func(idx):
		index.value = idx;
		on_waiting.emit();
	
	player.on_move.connect(callable, Object.CONNECT_ONE_SHOT)
	player.next_move(_board.duplicate())
	
	if index.value == -1:
		print("waiting for play: ", { player = player, current_player = _current_player });
		await on_waiting;
		print("wait done: ", player)
	
	return index.value;
	
func _declare_winner(winner: Winner) -> void:
	on_game_over.emit(winner)

func _switch_players() -> void:
	_current_player = _get_opponent(_current_player);
	on_switch_turns.emit(_players[_current_player], _current_player)
	
func _get_opponent(value: String) -> String:
	assert(_players.has(value));
	var player_values = _players.keys();
	return player_values[0] if value == player_values[1] else player_values[1];

func _to_string() -> String:
	return "Match { current_player = %s, players = %s }" % [_current_player, _players]
