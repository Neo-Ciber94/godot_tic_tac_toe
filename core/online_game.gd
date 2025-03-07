class_name OnlineGame;
extends Node

const PLAYER_DEFAULTS = {
	x = Color.RED,
	o = Color.BLUE
}

@onready var _lobby : MultiplayerLobby = $MultiplayerLobby;
@onready var _board: Board = $Board;
@onready var _game_over_message: ResultMessage = $ResultMessage;
@onready var _game_mode_label: GameModeLabel = $GameModeLabel;

# server only
var _outgoing_game_matches: Dictionary[int, Match] = {}

# common
signal on_online_match_ready()

var _players : Dictionary[String, Player] = {}
var _game_match: Match;
var _my_player: String;
var _my_peer_id: int;

func _ready():
	_game_over_message.hide();
	_board.on_hover.connect(_on_hover);
	
	start_game()

func start_game():	
	_setup_players();
	_start_match()
	
func _setup_players():
	print("starting online match: pvp")
	
	_my_peer_id = _start_server_or_connect();
	print("waiting for players...")
	
	var match_players = await _lobby.on_match_players_ready;
	
	if GameConfig.is_server:
		_server_setup_multiplayer_peers(match_players);
	else:
		await on_online_match_ready;
		
	print("ready to start...", { _my_peer_id = _my_peer_id })
	
func _start_server_or_connect() -> int:
	if GameConfig.is_server:
		return _lobby.create_server()
	else:
		return _lobby.create_client()
		
func _server_setup_multiplayer_peers(match_players):
	var turn_players: Array[String] = PLAYER_DEFAULTS.keys();
	turn_players.shuffle();
	
	var cur_player =  turn_players.pick_random()
	
	var online_players = {}
	online_players.set(turn_players[0], match_players[0].peer_id)
	online_players.set(turn_players[1], match_players[1].peer_id)

	for idx in match_players.size():
		var my_player = turn_players[idx];
		var peer_id = match_players[idx].peer_id;
		
		_on_peer_player_assign.rpc_id(peer_id, {
			peer_id = peer_id,
			my_player = my_player,
			cur_player = cur_player,
			online_players = online_players
		})
		
	_on_match_ready.rpc()		

func _start_match():
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
	_start_match();
	
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

func _on_game_start(players: Dictionary[String, Player], current_player: String):
	pass

func _on_switch_player(player: Player, value: String):
	pass

@rpc("authority", "call_local", "reliable")
func _on_peer_player_move(idx: int):
	print("_on_peer_player_move: ", {
		_my_peer_id = _my_peer_id,
		idx = idx,
		_my_player = _my_player,
	});
	
	for player in _players.values():
		var online_player: OnlinePlayer = player;
		online_player.on_move.emit(idx)		
		
@rpc("any_peer", "call_local", "reliable")	
func _on_peer_request_move(idx: int):
	# Only the server can validate moves and relay moves
	if not GameConfig.is_server:
		return;
		
	print("_on_peer_request_move: ", {
		_my_peer_id = _my_peer_id,
		idx = idx,
		_my_player = _my_player,
	});
	
	# get the player with the given sender id
	var remote_peer_id = multiplayer.get_remote_sender_id();
	var entry = Utils.find_dictionary_entry(_players, func(k,v): return v.peer_id == remote_peer_id)
	print("entry: ", entry)
	
	if entry == null:
		print("peer player not found: ", remote_peer_id);
		return;
		
	var peer_player_value = entry.key;
	var peer_online_player = entry.value as OnlinePlayer; 

	# Check if the player can make the move	
	#if peer_online_player.peer_id == remote_peer_id && _current_player == peer_player_value:
		## relay to all clients
		#_on_peer_player_move.rpc(idx);

@rpc("authority", "call_local", "reliable")	
func _on_peer_player_assign(player_info):
	print("_on_peer_player_assign: ", {
		_my_peer_id = _my_peer_id,
		player_info = player_info
	});

	var peer_id = player_info.peer_id;
	_my_peer_id = peer_id;
	_my_player = player_info.my_player;
	#_current_player = player_info.cur_player;
	
	for player in player_info.online_players:
		var player_peer_id = player_info.online_players.get(player)
		var player_move_rpc = Callable(func(idx):
			_on_peer_request_move.rpc(idx)
		)
		
		#_players[player] = OnlinePlayer.new(board, player_peer_id, player_move_rpc)
		
@rpc("authority", "call_local", "reliable")	
func _on_match_ready():
	on_online_match_ready.emit()
	print("_on_match_ready: ", _players)

@rpc("any_peer", "call_local", "reliable")		
func _on_start_online_game():
	print("_on_start_online_game: ", { _my_peer_id = _my_peer_id })
	#on_start_game.emit()
