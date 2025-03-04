extends Node2D

@onready var lobby: MultiplayerLobby = $MultiplayerLobby
@onready var box: ColorRect = $Box;

const COLORS = [Color.RED, Color.BLUE, Color.YELLOW, Color.GREEN, Color.ORANGE, Color.CYAN];

var my_peer_id: int;
var players: Dictionary[int, Color] = {}

func _ready():
	await _initialize();

func _initialize():
	my_peer_id = _start_multiplayer_peer();
	print("initialized with peer_id: ", my_peer_id);
	print("waiting...", { is_server = GameConfig.is_server })
	var match_players = await lobby.on_match_players_ready;
	print("match players: ", match_players)
	
	# assign the player colors
	for idx in match_players.size():
		var p = match_players[idx];
		var color = COLORS[idx % COLORS.size()];
		_assign_color.rpc(p.peer_id, color)

	
func _start_multiplayer_peer():
	if GameConfig.is_server:
		return lobby.create_server()
	else:
		return lobby.create_client()
			
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			var mouse_pos = event.position 
			var color = players[my_peer_id];
			print("clicked: ", { my_peer_id = my_peer_id, players = players})
			place_box.rpc(mouse_pos, color)

@rpc("authority", "call_local", "reliable")
func _assign_color(peer_id: int, color: Color):
	players[peer_id] = color;
	print("assign color: ", {
		my_peer_id = my_peer_id,
		peer_id = peer_id,
		color = color
	})

@rpc("any_peer", "call_local", "reliable")
func place_box(pos: Vector2i, color: Color):
	print("Mouse clicked at: ", {
		my_peer_id = my_peer_id,
		pos = pos,
		color = color,
	})
			
	var new_box: ColorRect = box.duplicate()
	add_child(new_box)
	
	new_box.color = color;
	new_box.position = pos;
	new_box.show();
