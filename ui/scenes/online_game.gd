class_name OnlineGame;
extends Node

@onready var _board: Board = $Board;
@onready var _message_display: MessageDisplay = $MessageDisplay;

var _players : Dictionary[String, Player] = {}
var _my_player: String;
var _my_peer_id: int;
var _board_state: Array[String];
var _current_player: String;
var _is_finished = false;

func _ready():
	_board.hide();
	_message_display.show();
	_message_display.set_message_size(MessageDisplay.Size.MEDIUM)
	_message_display.set_message_effect(MessageDisplay.Effect.PULSE)
	_message_display.show_message("Waiting for players...");
	
	_board.on_hover.connect(_on_hover);
	_board.on_click.connect(_on_click);
	
	NetworkManagerInstance.join_game.rpc()
	NetworkManagerInstance.on_sync_game_state.connect(_on_sync_game_state)
	NetworkManagerInstance.on_game_start.connect(_on_game_start)
	NetworkManagerInstance.on_game_over.connect(_on_game_over)
	NetworkManagerInstance.on_player_move.connect(_on_player_move)
	NetworkManagerInstance.on_switch_turns.connect(_on_switch_turns)
	NetworkManagerInstance.on_game_match_terminated.connect(_on_game_match_terminated)

func _on_sync_game_state(board_state: Array[String], current_player: String):
	_board_state = board_state;
	_current_player = current_player;
	
func _on_game_start(players: Dictionary[String, Player], my_player: String, current_player: String):
	_players = players;
	_current_player = current_player;
	_my_player = my_player;
	_is_finished = false;
	
	_message_display.hide();
	_board.show()
	_board.prepare_board();
	_board.fill_slots(Constants.EMPTY, Color.TRANSPARENT)
	await _board.show_board(true)

func _on_player_move(player: Player, value: String, index: int):
	print("_on_player_move: ", { player = player, value = value, index = index, _my_peer_id = _my_peer_id })
	
	if not value in _players:
		return;
	
	var color = Constants.PLAYER_DEFAULTS[value];
	_board.set_slot_value(index, value, color, true);
	_board_state[index] = value;

func _on_switch_turns(_player: Player, value: String):
	_current_player = value;

func _on_game_over(winner: Winner):
	var indices = winner.get_indices()
	_board.show_board(false)
	await _board.hide_slots(indices);
	
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
	NetworkManagerInstance.restart_match.rpc();
	
func _on_game_match_terminated(reason: NetworkManager.GameTerminationReason):
	var msg = (
		"Player Timeout" if reason == NetworkManager.GameTerminationReason.TIMEOUT
		else "Player Quit" if reason == NetworkManager.GameTerminationReason.PLAYER_QUIT
		else "Done with you" if reason == NetworkManager.GameTerminationReason.JUST_BECAUSE
		else "Game was terminated" # unreachable
	)
	
	_is_finished = true;
	_board.hide();
	_message_display.show_message(msg, Color.RED);

func _has_value(index: int):
	return _board_state[index] != Constants.EMPTY

func _on_click(_slot: Slot, index: int):
	if _is_finished:
		return;

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
		var color = Constants.PLAYER_DEFAULTS[_current_player];
		slot.set_value(_current_player, Color(color, 0.5), false)
	else:
		slot.set_value(Constants.EMPTY, Color.TRANSPARENT, false)
