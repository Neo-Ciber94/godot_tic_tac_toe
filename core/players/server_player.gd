extends Player;
class_name ServerPlayer;

var peer_id: int;

func _init(peer_id: int):
	self.peer_id = peer_id;

func _to_string() -> String:
	return "ServerPlayer(%s)" % peer_id
