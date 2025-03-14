class_name LocalGame;
extends Node

@onready var _board: Board = $Board;
@onready var _message_display: MessageDisplay = $MessageDisplay;

var mode: Constants.GameMode = Application.game_mode;
var difficulty: CpuPlayer.Difficulty = Application.difficulty;

var _players : Dictionary[String, Player] = {}
var _game_match: Match;
var _my_player: String;

func _ready():
	_message_display.hide();
	_board.on_hover.connect(_on_hover);
	
	start_game()

func start_game():	
	_setup_players();
	_start_match()
	
func _setup_players():
	match mode:
		Constants.GameMode.LOCAL:
			Logger.debug("starting local match: pvp")			
			var values = Constants.PLAYER_DEFAULTS.keys().duplicate();
			values.shuffle();
			
			_players[values[0]] = HumanPlayer.new(_board);
			_players[values[1]] = HumanPlayer.new(_board);
		Constants.GameMode.CPU:
			Logger.debug("starting local match: pvc")			
			var values = Constants.PLAYER_DEFAULTS.keys().duplicate();
			values.shuffle();
			
			var p1 = values.pop_back();
			var p2 = values.pop_back();
			
			_players[p1] = HumanPlayer.new(_board);
			_players[p2] = CpuPlayer.new(p2, p1, difficulty)
		_:
			assert(false, "only local and cpu are allowed")
	
func _start_match():
	_board.show();
	_board.prepare_board();
	_board.fill_slots(Constants.EMPTY, Color.TRANSPARENT)

	_game_match = _get_or_create_game_match();
	_my_player = _game_match.get_current_player();
	await _board.show_board(true)
	
	_game_match.reset_board();
	_game_match.start_match();

func _get_or_create_game_match() -> Match:
	if _game_match:
		return _game_match;
		
	_game_match = Match.new();
	_game_match.add_players(_players.duplicate(true));
	add_child(_game_match);
	
	_game_match.on_player_move.connect(_on_player_move)
	_game_match.on_game_over.connect(_on_game_over)
	_game_match.on_game_start.connect(_on_game_start)
	_game_match.on_switch_turns.connect(_on_switch_player);
	return _game_match;

func _on_player_move(player: Player, value: String, index: int):
	Logger.debug("_on_player_move: ", { player = player, value = value, index = index })
	
	if not value in _players:
		return;
	
	var color = Constants.PLAYER_DEFAULTS[value];
	_board.set_slot_value(index, value, color, true);

func _on_game_over(winner: Winner):
	var indices = winner.get_indices()
	_board.show_board(false)
	await _board.highlight_winner(indices);
	
	# Show the winner result_message
	if winner.is_tie():
		_message_display.show_message("It's a tie");
	else:
		var color = Constants.PLAYER_DEFAULTS[winner.get_value()];
		_message_display.show_message("winner!", color)
		
	_message_display.show();

	# Wait to click for restart
	await _message_display.on_click;
	_message_display.hide();
	_game_match.reset_board();
	_start_match();
	
func _on_hover(slot: Slot, index: int, is_over: bool):
	if _game_match.has_value(index):
		return;
		
	if _my_player != _game_match.get_current_player():
		return;
	
	if is_over:
		var current_player = _game_match.get_current_player();
		var color = Constants.PLAYER_DEFAULTS[current_player];
		slot.set_value(current_player, Color(color, 0.5), false)
	else:
		slot.set_value(Constants.EMPTY, Color.TRANSPARENT, false)

func _on_game_start(players: Dictionary[String, Player], current_player: String):
	match mode:
		# on pvp any player its the current player
		Constants.GameMode.LOCAL:
			_my_player = current_player;
		
		# on pvc the human player its the current player
		Constants.GameMode.CPU:
			for player_value in _players:
				var player = _players.get(player_value);
				
				if player is HumanPlayer:
					_my_player = player_value;
					Logger.debug("_assign: ", { _my_player = _my_player, players = players })
					return;

func _on_switch_player(player: Player, value: String):
	if player is HumanPlayer:
		_my_player = value;
