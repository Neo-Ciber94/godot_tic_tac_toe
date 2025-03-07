extends Node
class_name Game;

@onready var board : Board = $Board;
@onready var result_message: ResultMessage = $ResultMessage;
@onready var exit_btn : Button = $ExitButton;
@onready var game_mode_label: Label = $GameMode;
@onready var lobby = $MultiplayerLobby;

enum Visibility {
	VISIBLE,
	HIDDEN
}

const EMPTY = " ";
const MARK_X = "x";
const MARK_O = "o";

const COLOR_EMPTY = Color(0, 0, 0, 0.5);
const COLOR_P1 = Color(1, 0, 0);
const COLOR_P2 = Color(0, 0, 1);

var _values: Array[String] = [];
var _winner: Winner = Winner.None();
var _is_first_game = true;
var _is_playing = false;

@export var _mode = GameConfig.game_mode;
@export var _difficulty = GameConfig.difficulty;

signal on_waiting_move();
signal on_game_over();
signal on_online_match_ready()
signal on_start_game();

var _players: Dictionary[String, Player] = {}
var _current_player: String;
var _my_player: String;
var _my_peer_id: int;
	
func _ready() -> void:	
	on_start_game.connect(start_game)
	exit_btn.pressed.connect(_go_to_main_menu)
	game_mode_label.text = _get_game_mode_text()
	
	# start game
	start_game();

func start_game():	
	_reset_state();
	_setup_board()
	await _setup_players()	
	
	_start_playing();
	
func _reset_state():
	_winner = Winner.None()
	result_message.hide();
	
	for player in _players.values() as Array[Player]:
		var connections = player.on_move.get_connections()
		for conn in connections:
			player.on_move.disconnect(conn.callable)
			
	for conn in on_waiting_move.get_connections():
		on_waiting_move.disconnect(conn.callable)
	
func _setup_board():
	_values = [];
	board.show();
	result_message.hide();
	
	board.prepare_board();
	board.fill_slots(EMPTY, COLOR_EMPTY);
	
	if !board.on_hover.is_connected(_on_cell_hover):
		board.on_hover.connect(_on_cell_hover)
	
	for idx in range(9):		
		_values.push_back(EMPTY)

	# We show an initial delay at the first game
	if _is_first_game:
		_is_first_game = false;
		board.hide_lines()
		
func _on_cell_hover(slot: Slot, index: int, is_over: bool):
	if !can_hover(index):
		return;
		
	if is_over:
		slot.set_value(_current_player, Color(get_player_color(), 0.2))
	else:
		slot.set_value(EMPTY, COLOR_EMPTY)

func _setup_players():			
	if !_players.is_empty():
		return;
	
	match _mode:
		Constants.GameMode.LOCAL:
			print("start vs local")			
			_current_player = MARK_X;
			_my_player = _current_player;
			_players[MARK_X] = HumanPlayer.new(board)
			_players[MARK_O] = HumanPlayer.new(board)
		Constants.GameMode.CPU:
			print("start vs cpu")
			const turn_players: Array[String] = [MARK_X, MARK_O]
			_current_player =  turn_players.pick_random()
			_my_player = MARK_X;
			
			_players[MARK_X] = HumanPlayer.new(board)
			_players[MARK_O] = CpuPlayer.new(MARK_O, _difficulty)
		Constants.GameMode.ONLINE:
			print("start vs online")
			_my_peer_id = _start_server_or_connect();
			print("waiting for players...")
			
			var match_players = await lobby.on_match_players_ready;
			
			if GameConfig.is_server:
				_setup_multiplayer_peers(match_players);
			else:
				await on_online_match_ready;
				
			print("ready to start...", { _my_peer_id = _my_peer_id })
			
	# Append the players to the scene
	add_child(_players[MARK_X]);
	add_child(_players[MARK_O]);

func _start_server_or_connect() -> int:
	if GameConfig.is_server:
		return lobby.create_server()
	else:
		return lobby.create_client()

func _setup_multiplayer_peers(match_players: Array[PlayerPeer]):
	var turn_players: Array[String] = [MARK_X, MARK_O];
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
	
func make_move(player: Player):
	var index = { value = -1 }
	
	var callable = func(idx):
		index.value = idx;
		on_waiting_move.emit();
	
	player.on_move.connect(callable, Object.CONNECT_ONE_SHOT)
	player.next_move(_values.duplicate())
	
	if index.value == -1:
		print("waiting for play: ", player);
		await on_waiting_move;
		print("wait done: ", player)
	
	return index.value;

func _start_playing():		
	await board.show_board(true)
	
	_is_playing = true;
	
	while(not _winner.is_finished()):
		var player = _players[_current_player];
		print("current player: ", _current_player)
		
		print("waiting for: ", _current_player)
		var index = await make_move(player);
		print(_current_player, " move to ", index);
		
		if has_value(index):
			print("illegal play: ", index)
			continue;
	
		await set_value(_current_player, index);
		#refresh_ui();
		self.print_board()

		if _winner.is_finished():
			break;
		else:
			switch_player()
	
	print("game its over")
	_is_playing = false;
	_finalize_game();
	
func _finalize_game():
	var indices = _winner.get_indices()
	board.show_board(false)
	await board.hide_slots(indices);
	
	# Show the winner result_message
	if _winner.is_tie():
		result_message.change_text("It's a tie", Color.BLACK);
	else:
		var color = Game.get_color(_winner.get_value());
		result_message.change_text("winner!", color)
		
	result_message.show();

	# Wait to click for restart
	await result_message.on_click;
	
	if _mode == Constants.GameMode.ONLINE:
		_on_start_online_game.rpc()	
	else:
		start_game()
		
func get_value(index: int):
	return _values[index]

func has_value(index: int):
	return get_value(index) != EMPTY;
	
func set_value(value: String, index: int):
	if has_value(index):
		print("board index '", index, "' it's already set");
		return;
		
	_values[index] = value;
	await board.set_slot_value(index, value, get_player_color())
	var winner = Utils.check_winner(_values, EMPTY);
	
	if winner.is_finished():
		print("finished: ", winner)
		_winner = winner;
		on_game_over.emit()

func can_hover(index: int):
	#if !_players.has(_current_player):
		#return false;
		
	if _my_player != _current_player:
		return false;
		
	if has_value(index):
		return false;

	return _is_playing && !is_game_over()

func is_game_over():
	return _winner.is_finished()

func get_player_color():
	return Game.get_color(_current_player)
	
func switch_player():
	_current_player = Game.get_opponent(_current_player)
	
	if _mode == Constants.GameMode.LOCAL:
		_my_player = _current_player;

func _go_to_main_menu():
	await board.show_board(false)
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func refresh_ui():
	for idx in _values.size():
		var value = _values[idx];
		var color = Game.get_color(value)
		board.set_slot_value(idx, value, color)
		
	await on_waiting_move;

func _get_game_mode_text():
	match _mode:
		Constants.GameMode.LOCAL:
			return "Mode: Local"
		Constants.GameMode.CPU:
			var difficulty = (
				"Easy" if _difficulty == CpuPlayer.Difficulty.RANDOM
				else "Easy" if _difficulty == CpuPlayer.Difficulty.EASY
				else "Hard" if _difficulty == CpuPlayer.Difficulty.HARD
				else "Impossible" if _difficulty == CpuPlayer.Difficulty.IMPOSSIBLE
				else "" # unreachable
			)
			
			return "Mode: CPU (%s)" % difficulty;
		Constants.GameMode.ONLINE:
			return "Mode: Online"

func get_peer_ids() -> Array[int]:
	var peer_ids : Array[int] = [];
	
	for player in _players.values():
		if player is OnlinePlayer:
			peer_ids.push_back(player.peer_id)
	
	return peer_ids;

func print_board():
	print("=== ", multiplayer.multiplayer_peer.get_unique_id())
	print("=== ", _values.slice(0, 3))
	print("=== ", _values.slice(3, 6))
	print("=== ", _values.slice(6, 9))
	
@rpc("authority", "call_local", "reliable")
func _on_peer_player_move(idx: int):
	print("_on_peer_player_move: ", {
		_my_peer_id = _my_peer_id,
		idx = idx,
		_my_player = _my_player,
		_current_player = _current_player,
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
		_current_player = _current_player,
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
	if peer_online_player.peer_id == remote_peer_id && _current_player == peer_player_value:
		# relay to all clients
		_on_peer_player_move.rpc(idx);

@rpc("authority", "call_local", "reliable")	
func _on_peer_player_assign(player_info):
	print("_on_peer_player_assign: ", {
		_my_peer_id = _my_peer_id,
		player_info = player_info
	});

	var peer_id = player_info.peer_id;
	_my_peer_id = peer_id;
	_my_player = player_info.my_player;
	_current_player = player_info.cur_player;
	
	for player in player_info.online_players:
		var player_peer_id = player_info.online_players.get(player)
		var player_move_rpc = Callable(func(idx):
			_on_peer_request_move.rpc(idx)
		)
		
		_players[player] = OnlinePlayer.new(board, player_peer_id, player_move_rpc)
		
@rpc("authority", "call_local", "reliable")	
func _on_match_ready():
	on_online_match_ready.emit()
	print("_on_match_ready: ", _players)

@rpc("any_peer", "call_local", "reliable")		
func _on_start_online_game():
	print("_on_start_online_game: ", { _my_peer_id = _my_peer_id })
	on_start_game.emit()
	
static func get_opponent(value: String):
	return MARK_O if value == MARK_X else MARK_X
	
static func get_color(value: String):
	match value:
		MARK_X:
			return COLOR_P1;
		MARK_O:
			return COLOR_P2;
		_:
			return Color(0, 0, 0, 0.5);
