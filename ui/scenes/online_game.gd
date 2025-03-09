class_name OnlineGame;
extends Node

const PLAYER_DEFAULTS = {
	x = Color.RED,
	o = Color.BLUE
}

@onready var _board: Board = $Board;
@onready var _game_over_message: ResultMessage = $ResultMessage;

var _players : Dictionary[String, Player] = {}
var _my_player: String;
var _my_peer_id: int;
var _board_state: Array[String];
var _current_player: String;
var _is_finished = false;

func _ready():
	_board.hide();
	_game_over_message.show();
	_game_over_message.change_text("Waiting for players...");
	
	_board.on_hover.connect(_on_hover);
	_board.on_click.connect(_on_click);
	
	NetworkManagerInstance.on_sync_game_state.connect(_on_sync_game_state)
	NetworkManagerInstance.on_game_start.connect(_on_game_start)
	NetworkManagerInstance.on_game_over.connect(_on_game_over)
	NetworkManagerInstance.on_player_move.connect(_on_player_move)
	NetworkManagerInstance.on_switch_turns.connect(_on_switch_turns)

func _on_sync_game_state(board_state: Array[String], current_player: String):
	_board_state = board_state;
	_current_player = current_player;
	
func _on_game_start(players: Dictionary[String, Player], my_player: String, current_player: String):
	_players = players;
	_current_player = current_player;
	_my_player = my_player;
	_is_finished = false;
	
	_game_over_message.hide();
	_board.show()
	_board.prepare_board();
	_board.fill_slots(Constants.EMPTY, Color.TRANSPARENT)
	await _board.show_board(true)

func _on_player_move(player: Player, value: String, index: int):
	print("_on_player_move: ", { player = player, value = value, index = index, _my_peer_id = _my_peer_id })
	
	if not value in _players:
		return;
	
	var color = PLAYER_DEFAULTS[value];
	_board.set_slot_value(index, value, color, true);
	_board_state[index] = value;

func _on_switch_turns(player: Player, value: String):
	_current_player = value;

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
	NetworkManagerInstance.restart_match.rpc();


func _has_value(index: int):
	return _board_state[index] != Constants.EMPTY

func _on_click(_slot: Slot, index: int):
	if _my_player != _current_player:
		print("not your turn")
		return;
		
	if _has_value(index):
		print("value already set")
		return;
		
	NetworkManagerInstance.request_move.rpc(index)
	_board_state[index] = _my_player;
	
func _on_hover(slot: Slot, index: int, is_over: bool):
	if _has_value(index):
		return;
		
	if _my_player != _current_player:
		return;
	
	if is_over:
		var color = PLAYER_DEFAULTS[_current_player];
		slot.set_value(_current_player, Color(color, 0.5), false)
	else:
		slot.set_value(Constants.EMPTY, Color.TRANSPARENT, false)
