extends Node

class_name Match;

const EMPTY := " "

var _board: Array[String] = []
var _players: Dictionary[String, Player] = {};
var _current_player: String;

signal on_player_move(value: String, idx: int);
signal on_game_over(winner: Winner);

func _ready():
	reset_board()

func set_players(players: Dictionary[String, Player]):
	var player_values = players.keys();
	assert(player_values.size() == 2, "expected 2 players");
	assert(player_values[0] != player_values[1], "players should be different");
	
	_players = players;
	
func reset_board():
	for idx in range(9):
		_board.push_back(EMPTY);
		
func start_match():
	assert(_players.size() == 2, "expected 2 players to start the match");
	
	while(true):
		var player = _players[_current_player];
		var index = await _get_next_move(player);
		_board[index] = _current_player;
		on_player_move.emit(_current_player, index);
		
		var winner = Utils.check_winner(_board, EMPTY);
		
		if winner.is_finished():
			_declare_winner(winner);
			break;
	
func _get_next_move(player: Player) -> int:
	var idx = 0;
	return 0;
	
func _declare_winner(winner: Winner):
	on_game_over.emit(winner)
	pass

func switch_players():
	_current_player = _get_opponent(_current_player);
	
func _get_opponent(value: String) -> String:
	assert(_players.has(value));
	var player_values = _players.values();
	return player_values[0] if value == player_values[1] else player_values[0];
