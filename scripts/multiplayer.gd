class_name Multiplayer;
extends Node

const SERVER_ID = 1;

@export var host = "127.0.0.1"
@export var port = 7000;
@export var max_clients = 1000;

signal on_player_connected(player: PlayerPeer);
signal on_player_disconnected(player: PlayerPeer);

signal on_connection_ok();
signal on_connection_failed();
signal on_server_disconnected();

var _connected_players: Dictionary[int, PlayerPeer] = {}
var _my_peer_id: int; # the peer id for the server/client that started

func _ready():
	_bind_listeners()
	
func _bind_listeners():
	# emitted to all
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# emitted to clients only
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
func create_server() -> int:
	var peer = ENetMultiplayerPeer.new();
	var err = peer.create_server(port, max_clients);
	
	if err:
		print("failed to start server");
		return 0;
		
	print("server started");
	multiplayer.multiplayer_peer = peer;
	
	var peer_id = peer.get_unique_id();
	
	if peer_id != SERVER_ID:
		_register_player(peer_id);
		
	_my_peer_id = peer_id;
	return peer_id;
	
func create_client() -> int:
	var peer = ENetMultiplayerPeer.new();
	var err = peer.create_client(host, port);
	
	if err:
		print("failed to connect to server");
		return 0;
		
	print("client connected to server");
	multiplayer.multiplayer_peer = peer;
	var peer_id = peer.get_unique_id()
	
	_my_peer_id = peer_id;
	return peer_id;

func get_connected_players() -> Dictionary[int, PlayerPeer]:
	return _connected_players.duplicate()

func _register_player(peer_id: int):
	print("_register_player: ", { peer_id = peer_id });
	var player = PlayerPeer.new(peer_id);
	_connected_players[peer_id] = player;
	
	on_player_connected.emit(player);
	
func _remove_player(peer_id: int):
	print("_remove_player: ", { peer_id = peer_id });
	var player_to_remove = _connected_players.get(peer_id)
	_connected_players.erase(peer_id);
	
	if player_to_remove:
		on_player_disconnected.emit(player_to_remove)

func _on_peer_connected(peer_id: int):
	print("_on_peer_connected: ", { peer_id = peer_id })
	if peer_id == SERVER_ID:
		return;
	
	_register_player(peer_id)
	
func _on_peer_disconnected(peer_id: int):		
	print("_on_peer_disconnected")
	_remove_player(peer_id)

func _on_connected_to_server():
	var peer_id = multiplayer.get_unique_id()
	print("_on_connected_to_server, peer_id: ", { peer_id = peer_id })
	_register_player(peer_id)
	on_connection_ok.emit();

func _on_connection_failed():
	print("_on_connection_failed")
	multiplayer.multiplayer_peer = null
	on_connection_failed.emit();

func _on_server_disconnected():
	print("_on_server_disconnected")
	multiplayer.multiplayer_peer = null
	_connected_players.clear()
	on_server_disconnected.emit();

func get_my_peer_id():
	return _my_peer_id;
