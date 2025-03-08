class_name NetworkManager;
extends Node

class OnlineMatch:
	var game_match: Match;
	var peer_ids: Array[int];
	
	func _init(game_match: Match, peer_ids: Array[int]):
		self.game_match = game_match;
		self.peer_ids = peer_ids;

var _server_outgoing_matches: Dictionary[int, OnlineMatch] = {}
var _server_players_queue: Array[ServerPlayer] = [];

var _my_player: String;
var _outgoing_player: OnlinePlayer;

signal on_player_move(player: Player, value: String, index: int);
signal on_game_over(winner: Winner);
signal on_game_start(players: Dictionary[String, Player], my_player: String, current_player: String);
signal on_switch_turns(player: Player, value: String);
signal on_sync_game_state(board_state: Array[String], current_player: String);

func _ready():
	# start the server or client
	if GameConfig.is_server:
		MultiplayerInstance.create_server()
	else:
		MultiplayerInstance.create_client()
		
	if multiplayer.is_server():
		# connect the events to clients and servers and clients can track players
		MultiplayerInstance.on_player_connected.connect(_on_player_connected);
		MultiplayerInstance.on_player_disconnected.connect(_on_player_disconnected)

func _on_player_connected(player_peer: PlayerPeer):
	var peer_id = player_peer.peer_id;
	
	var player = ServerPlayer.new(peer_id)
	_server_players_queue.push_back(player);
	_server_check_can_start_match();

func _on_player_disconnected(player_peer: PlayerPeer):
	var index = _server_players_queue.find_custom(func(p): return p.peer_id == player_peer.peer_id);
	
	if index >= 0:
		_server_players_queue.remove_at(index);
	
func _server_check_can_start_match():
	if _server_players_queue.size() < 2:
		return;
	
	var values = ["x", "o"];
	values.shuffle();
		
	var p1: ServerPlayer = _server_players_queue.pop_front();
	var p2: ServerPlayer = _server_players_queue.pop_front();
	var game_match = Match.new();
	add_child(game_match);
	_add_online_match(game_match, p1.peer_id, p2.peer_id);
	
	var players: Dictionary[String, Player] = {};
	players[values[0]] = p1;
	players[values[1]] = p2;
	game_match.add_players(players);

	# bind listeners to match to notify clients
	var peer_ids: Array[int] = [p1.peer_id, p2.peer_id];
	game_match.on_game_start.connect(_server_on_game_start)
	game_match.on_player_move.connect(_server_on_player_move)
	game_match.on_switch_turns.connect(_server_on_switch_turns);
	game_match.on_game_over.connect(func(winner): _server_on_game_over(peer_ids, winner))
	
	# start
	print("starting match: ", { p1 = p1, p2 = p2 });
	_server_sync_game_state(p1.peer_id, p2.peer_id);
	game_match.start_match()
	
	# notify the clients to start the match
	var player_peers_map: Dictionary[String, int] = {}
	for player_value in players:
		var server_player: ServerPlayer = players.get(player_value);
		player_peers_map[player_value] = server_player.peer_id;
		
	#for player_value in players:
		#var server_player: ServerPlayer = players.get(player_value);
		#_server_match_ready.rpc_id(server_player.peer_id, 
			#player_value,
			#game_match.get_current_player(),
			#player_peers_map
		#)

func _add_online_match(game_match: Match, peer_1: int, peer_2: int):
	var online_match = OnlineMatch.new(game_match, [peer_1, peer_2]);
	_server_outgoing_matches.set(peer_1, online_match);
	_server_outgoing_matches.set(peer_2, online_match);

func _server_on_game_start(players: Dictionary[String, Player], current_player: String):
	print("_server_on_game_start")
	var server_players: Dictionary[String, int] = {};
	
	for player_value in players:
		var player : ServerPlayer = players.get(player_value);
		server_players[player_value] = player.peer_id;
		
	for my_player in server_players:
		var peer_id = server_players.get(my_player);
		_notify_on_game_start.rpc_id(peer_id, server_players, my_player, current_player);
	
@rpc("authority", "call_remote", "reliable")
func _notify_on_game_start(server_players: Dictionary[String, int], my_player: String, current_player: String):
	print("_notify_on_game_start: ", { my_peer_id = MultiplayerInstance.get_my_peer_id() })
	var players : Dictionary[String, Player] = {};
	
	for player_value in server_players:
		var peer_id = server_players.get(player_value);
		var player = ServerPlayer.new(peer_id);
		players.set(player_value, player);
		
	on_game_start.emit(players, my_player, current_player)
	
func _server_on_game_over(peer_ids: Array[int], winner: Winner):
	for peer_id in peer_ids:
		_notify_on_game_over.rpc_id(peer_id, winner.to_json())
	
@rpc("authority", "call_remote", "reliable")
func _notify_on_game_over(winner_json: String):
	var winner = Winner.from_json(winner_json);
	on_game_over.emit(winner);
	
func _server_on_switch_turns(player: Player, value: String):
	var server_player: ServerPlayer = player;
	var online_match: OnlineMatch = _server_outgoing_matches.get(server_player.peer_id);
	
	if online_match == null:
		return;
		
	for peer_id in online_match.peer_ids:
		_notify_switch_turns.rpc_id(peer_id, server_player.peer_id, value);
	
@rpc("authority", "call_remote", "reliable")
func _notify_switch_turns(player_peer_id: int, value: String):
	on_switch_turns.emit(ServerPlayer.new(player_peer_id), value);

func _server_on_player_move(player: Player, value: String, index: int):
	print("_server_on_player_move")
	var server_player = player as ServerPlayer;
	var online_match: OnlineMatch = _server_outgoing_matches.get(server_player.peer_id);
	
	if online_match == null:
		return;
		
	for peer_id in online_match.peer_ids:
		_notify_player_move.rpc_id(peer_id, server_player.peer_id, value, index);

@rpc("authority", "call_remote", "reliable")
func _notify_player_move(player_peer_id: int, value: String, index: int):
	var player = ServerPlayer.new(player_peer_id);
	on_player_move.emit(player, value, index);
	
func _server_sync_game_for_all_players_in_match(any_player_peer_id: int):
	var online_match: OnlineMatch = _server_outgoing_matches.get(any_player_peer_id);
	
	if online_match == null:
		return;
		
	var peer_ids = online_match.peer_ids;
	_server_sync_game_state(peer_ids[0], peer_ids[1]);

func _server_sync_game_state(peer_1: int, peer_2: int):
	var online_match: OnlineMatch = _server_outgoing_matches.get(peer_1);
	
	if online_match == null:
		return;
		
	var game_match: Match = online_match.game_match;
	var board = game_match.get_board_state();
	var current_player = game_match.get_current_player();
	
	_notify_sync_game_state.rpc_id(peer_1, board, current_player)
	_notify_sync_game_state.rpc_id(peer_2, board, current_player)
	
@rpc("authority", "call_remote", "reliable")
func _notify_sync_game_state(board: Array[String], current_player: String):
	on_sync_game_state.emit(board, current_player)

@rpc("authority", "call_remote", "reliable")
func _server_make_move(peer_id: int, index: int):
	print("make_move: ", { peer_id = peer_id, index = index })
	var online_match: OnlineMatch = _server_outgoing_matches.get(peer_id);
	var game_match = online_match.game_match;
	
	var players = game_match.get_players();
	for player_value in players:
		var player: OnlinePlayer = players.get(player_value);
		player.on_move.emit(index);
	
@rpc("any_peer", "call_remote", "reliable")
func request_move(index: int):
	if not multiplayer.is_server():
		return;

	print("request_move: ", index);
	var remove_peer_id = multiplayer.get_remote_sender_id();
	var online_match: OnlineMatch = _server_outgoing_matches.get(remove_peer_id);
	
	if online_match == null:
		print("online match was not found: ", { remove_peer_id = remove_peer_id });
		return;
	
	var game_match = online_match.game_match;	
	var player: ServerPlayer = game_match.get_turn_player();
	
	if player.peer_id != remove_peer_id:
		print("not your turn: ", {
			remove_peer_id = remove_peer_id,
			turn_player = player
		})
		return;
	
	player.on_move.emit(index);
