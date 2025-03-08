class_name NetworkManager;
extends Node

class OnlineMatch:
	var game_match: Match;
	
	func _init(game_match: Match):
		self.game_match = game_match;

var _server_match_id = 0;
var _server_outgoing_matches: Dictionary[int, OnlineMatch] = {}
var _server_players_queue: Array[ServerPlayer] = [];

signal on_match_ready(my_player: String, game_match: Match);

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
	_server_remove_player(player_peer);
	
func _server_check_can_start_match():
	if _server_players_queue.size() < 2:
		return;
	
	var values = ["x", "o"];
	values.shuffle();
		
	var p1: ServerPlayer = _server_players_queue.pop_front();
	var p2: ServerPlayer = _server_players_queue.pop_front();
	var game_match = Match.new();
	add_child(game_match);
	
	var players: Dictionary[String, Player] = {};
	players[values[0]] = p1;
	players[values[1]] = p2;
	game_match.add_players(players);

	var online_match = OnlineMatch.new(game_match);
	_server_outgoing_matches.set(p1.peer_id, online_match);
	_server_outgoing_matches.set(p2.peer_id, online_match);
	
	# bind listeners to match to notify clients
	# game_match.on_game_over.connect(...)
	# game_match.on_game_start.connect(...)
	# game_match.on_player_move.connect(...)
	
	# start
	print("starting match: ", { p1 = p1, p2 = p2 });
	game_match.start_match()
	
	# notify the clients to start the match
	var player_peers_map: Dictionary[String, int] = {}
	for player_value in players:
		var server_player: ServerPlayer = players.get(player_value);
		player_peers_map[player_value] = server_player.peer_id;
		
	for player_value in players:
		var server_player: ServerPlayer = players.get(player_value);
		_server_match_ready.rpc_id(server_player.peer_id, 
			player_value,
			game_match.get_current_player(),
			player_peers_map
		)

	
func _server_remove_player(player_peer: PlayerPeer):		
	var idx = _server_players_queue.find_custom(func(p): return p.peer_id == player_peer.peer_id);
	
	if idx >= 0:
		_server_players_queue.remove_at(idx);

func _get_next_server_match_id() -> int:
	_server_match_id += 1;
	return _server_match_id;
	
@rpc("authority", "call_remote", "reliable")
func _server_match_ready(my_player: String, current_player: String, player_peers: Dictionary[String, int]):
	var players: Dictionary[String, Player] = {}
	
	for player_value in player_peers:
		var peer_id = player_peers[player_value];
		var move_rpc = func(idx): request_move(idx);
		var online_player = OnlinePlayer.new(peer_id, move_rpc);
		players[player_value] = online_player;
		
	var game_match = Match.new();
	game_match.add_players(players);
	game_match.set_current_player(current_player);
	on_match_ready.emit(my_player, game_match);
	
@rpc("authority", "call_local", "reliable")
func _server_make_move(peer_id: int, index: int):
	print("make_move: ", { peer_id = peer_id, index = index })
	pass
	
@rpc("any_peer", "call_remote", "reliable")
func request_move(index: int):
	if not multiplayer.is_server():
		return;
		
	var peer_id = multiplayer.get_remote_sender_id();
	var online_match: OnlineMatch = _server_outgoing_matches.get(peer_id);
	
	if online_match == null:
		print("online match was not found: ", { peer_id = peer_id });
		return;
		
	# TODO: Check if the player its the current player
		
	var game_match = online_match.game_match;	
	var player = game_match.get_turn_player();
	player.on_move.emit(index);
	_server_make_move.rpc(peer_id, index); # TODO: Send only to the peers of this match
