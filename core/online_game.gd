class_name OnlineGame;
extends Node

const PLAYER_DEFAULTS = {
	x = Color.RED,
	o = Color.BLUE
}

@onready var _board: Board = $Board;
@onready var _game_over_message: ResultMessage = $ResultMessage;
@onready var _game_mode_label: GameModeLabel = $GameModeLabel;

var _players : Dictionary[String, Player] = {}
var _game_match: Match;
var _my_player: String;

func _ready():
	_board.hide();
	_game_over_message.change_text("Waiting for players...");
	
	NetworkManagerInstance.on_match_ready.connect(_on_start_match)

func _on_start_match(my_player: String, game_match: Match):
	print("_on_start_match: ", {
		my_player = my_player,
		game_match = game_match,
	})
	
	add_child(game_match);
	
	_board.show()
	_board.prepare_board();
	_board.fill_slots(Constants.EMPTY, Color.TRANSPARENT)
	_board.on_hover.connect(_on_hover);
	_my_player = my_player;

	_game_match = game_match;
	game_match.on_player_move.connect(_on_player_move);
	game_match.on_game_over.connect(_on_game_over)
	await _board.show_board(true);
	
func _on_player_move(player: Player, value: String, index: int):
	print("_on_player_move: ", { player = player, value = value, index = index })
	
	if not value in _players:
		return;
	
	var color = PLAYER_DEFAULTS[value];
	_board.set_slot_value(index, value, color, true);

func _on_game_over(winner: Winner):
	var indices = winner.get_indices()
	_board.show_board(false)
	await _board.hide_slots(indices);
	
	# Show the winner result_message
	if winner.is_tie():
		_game_over_message.change_text("It's a tie", Color.BLACK);
	else:
		var color = PLAYER_DEFAULTS[winner.get_value()];
		_game_over_message.change_text("winner!", color)
		
	_game_over_message.show();

	# Wait to click for restart
	await _game_over_message.on_click;
	_game_over_message.hide();
	_game_match.reset_board();

func _on_hover(slot: Slot, index: int, is_over: bool):
	if _game_match.has_value(index):
		return;
		
	if _my_player != _game_match.get_current_player():
		return;
	
	if is_over:
		var current_player = _game_match.get_current_player();
		var color = PLAYER_DEFAULTS[current_player];
		slot.set_value(current_player, Color(color, 0.5), false)
	else:
		slot.set_value(Constants.EMPTY, Color.TRANSPARENT, false)
