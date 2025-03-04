extends Node
class_name MultiplayerLobby;

const SERVER_HOST = "127.0.0.1";
const SERVER_PORT = 7000;
const SERVER_MAX_CLIENTS = 1000;
const SERVER_PEER_ID = 1;

class PlayerPeer:
	var peer_id: int;
	
	func _init(peer_id: int):
		self.peer_id = peer_id;
		
	func _to_string():
		return "PlayerPeer(%s)" % peer_id

@export var is_server_player = false
@export var match_players_count = 2;

signal on_match_players_ready(players: Array[PlayerPeer]);
signal on_player_connected(player: PlayerPeer);
signal on_player_disconnected(player: PlayerPeer);

var _connected_players: Dictionary[int, PlayerPeer] = {}
var _players_queue: Array[PlayerPeer] = []

func _ready():
	assert(match_players_count >= 1, "A match requires 1 or more players");
	_bind_listeners()
	
func _bind_listeners():
	# emitted to all
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# emitted to clients only
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
func create_server():
	var peer = ENetMultiplayerPeer.new();
	var err = peer.create_server(SERVER_PORT, SERVER_MAX_CLIENTS);
	
	if err:
		print("failed to start server");
		return;
		
	print("server started");
	multiplayer.multiplayer_peer = peer;
	
	var peer_id = peer.get_unique_id();
	
	if is_server_player:
		_register_player(peer_id);
		
	return peer_id;
	
func create_client():
	var peer = ENetMultiplayerPeer.new();
	var err = peer.create_client(SERVER_HOST, SERVER_PORT);
	
	if err:
		print("failed to connect to server");
		return;
		
	print("client connected to server");
	multiplayer.multiplayer_peer = peer;
	var peer_id = peer.get_unique_id()
	
	return peer_id;

func _register_player(peer_id: int):
	print("_register_player: ", { peer_id = peer_id });
	var player = PlayerPeer.new(peer_id);
	_connected_players[peer_id] = player;
	_players_queue.push_back(player)
	
	on_player_connected.emit(player);
	_check_can_start_match();
	
func _remove_player(peer_id: int):
	print("_remove_player: ", { peer_id = peer_id });
	var player_to_remove = _connected_players.get(peer_id)
	_connected_players.erase(peer_id);
	
	for idx in _players_queue.size():
		var player = _players_queue[idx];
		
		if player.peer_id == peer_id:
			_players_queue.remove_at(idx)
			break;
	
	if player_to_remove:
		on_player_disconnected.emit(player_to_remove)

func _check_can_start_match():
	var player_count = _players_queue.size();
	
	if player_count >= match_players_count:
		var match_players: Array[PlayerPeer] = [];
		
		for _i in match_players_count:
			var p = _players_queue.pop_front();
			match_players.push_back(p);
		
		print("starting match with players: ", match_players)
		on_match_players_ready.emit(match_players)

func _on_peer_connected(peer_id: int):
	print("_on_peer_connected: ", { peer_id = peer_id })
	if peer_id == SERVER_PEER_ID && !is_server_player:
		return;
	
	_register_player(peer_id)
	
func _on_peer_disconnected(peer_id: int):		
	print("_on_peer_disconnected")
	_remove_player(peer_id)

func _on_connected_to_server():
	var peer_id = multiplayer.get_unique_id()
	print("_on_connected_to_server, peer_id: ", { peer_id = peer_id })
	_register_player(peer_id)

func _on_connection_failed():
	print("_on_connection_failed")
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	print("_on_server_disconnected")
	multiplayer.multiplayer_peer = null
	_connected_players.clear()
	_players_queue.clear()
