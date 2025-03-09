class_name PlayerPeer;
extends RefCounted;

var peer_id: int;

func _init(player_peer_id: int):
	self.peer_id = player_peer_id;
	
func _to_string():
	return "PlayerPeer(%s)" % peer_id
