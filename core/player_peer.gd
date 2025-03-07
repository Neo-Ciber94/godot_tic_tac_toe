class_name PlayerPeer;
extends RefCounted;

var peer_id: int;

func _init(peer_id: int):
	self.peer_id = peer_id;
	
func _to_string():
	return "PlayerPeer(%s)" % peer_id
