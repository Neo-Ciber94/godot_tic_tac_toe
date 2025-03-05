extends Node
class_name Game;

@onready var container = $Board/CellsContainer
@onready var board_grid = $Board/Grid
@onready var board_anim: AnimationPlayer = $Board/Grid/AnimationPlayer;
@onready var result_message: ResultMessage = $ResultMessage;
@onready var exit_btn : Button = $ExitButton;
@onready var game_mode_label: Label = $GameMode;
@onready var lobby = $MultiplayerLobby;

enum Mode {
	LOCAL,
	CPU,
	ONLINE
}

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

var _cells : Array[Cell] = [];
var _board: Array[String] = [];
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
	
	# start game
	start_game();

func start_game():
	_winner = Winner.None()
	game_mode_label.text = _get_game_mode_text()
	result_message.hide();
		
	setup_board()
	await setup_players()	
	start_playing();
		
func setup_board():
	_cells = [];
	_board = [];
	
	container.show();
	result_message.hide();
	
	for child in container.get_children():
			child.queue_free()
			
	var cell_scene = preload("res://ui/cell.tscn");
			
	for idx in 9:
		var cell = cell_scene.instantiate();
		container.add_child(cell);
		
		_board.push_back(EMPTY)
		_cells.push_back(cell);
		cell.draw_mark(EMPTY, COLOR_EMPTY);
		
		cell.on_hover.connect(func(this_cell, is_over): 
			on_cell_hover(this_cell, is_over, idx)	
		)
		
		# We show an initial delay at the first game
	if _is_first_game:
		_is_first_game = false;
		for child in board_grid.get_children():
			if child is Line2D:
				child.modulate.a = 0.0;

func on_cell_hover(cell: Cell, is_over: bool, index: int):
	if !can_hover(index):
		return;
			
	if is_over:
		var mark = get_player()
		cell.draw_mark(mark, Color(get_player_color(), 0.2))
	else:
		cell.draw_mark(EMPTY, COLOR_EMPTY)

func setup_players():			
	if !_players.is_empty():
		add_players_to_scene();
		return;
	
	match _mode:
		Mode.LOCAL:
			print("start vs local")			
			_current_player = MARK_X;
			_my_player = _current_player;
			_players[MARK_X] = HumanPlayer.new()
			_players[MARK_O] = HumanPlayer.new()
		Mode.CPU:
			print("start vs cpu")
			const turn_players: Array[String] = [MARK_X, MARK_O]
			_current_player =  turn_players.pick_random()
			_my_player = MARK_X;
			
			_players[MARK_X] = HumanPlayer.new()
			_players[MARK_O] = CpuPlayer.new(MARK_O, _difficulty)
		Mode.ONLINE:
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
	add_players_to_scene();

func _start_server_or_connect() -> int:
	if GameConfig.is_server:
		return lobby.create_server()
	else:
		return lobby.create_client()

func _setup_multiplayer_peers(match_players):
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

func add_players_to_scene():
	add_child(_players[MARK_X]);
	add_child(_players[MARK_O]);
	
func remove_players_from_scene():
	remove_child(_players[MARK_X])
	remove_child(_players[MARK_O])

func make_move(player: Player):
	var index = { value = -1 }
	
	var callable = func(idx):
		index.value = idx;
		on_waiting_move.emit();
	
	player.on_move.connect(callable, Object.CONNECT_ONE_SHOT)
	player.next_move(_cells.duplicate(), _board.duplicate())
	
	if index.value == -1:
		await on_waiting_move;
	
	return index.value;

func start_playing():		
	await change_board_visibility(Visibility.VISIBLE);
	
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
		refresh_ui();
		self.print_board()

		if _winner.is_finished():
			break;
		else:
			switch_player()
	
	print("game its over")
	_is_playing = false;
	
	change_board_visibility(Visibility.HIDDEN);
	await hide_cells();
	
	# Show the winner result_message
	if _winner.is_tie():
		result_message.change_text("It's a tie", Color.BLACK);
	else:
		var color = Game.get_color(_winner.get_value());
		result_message.change_text("winner!", color)
		
	result_message.show();

	# Wait to click for restart
	await result_message.on_click;
	
	remove_players_from_scene();
	board_grid.modulate.a = 1.0;
	
	if _mode == Mode.ONLINE:
		_on_start_online_game.rpc()	
	else:
		start_game()
	
func hide_cells():	
	var indices = _winner.get_indices()
	var winner_cells: Array[Cell] = [];
	var other_cells : Array[Cell] = [];
	
	for idx in _board.size():
		var is_winner_idx = indices.has(idx);
		var cell = _cells[idx]
		
		if is_winner_idx:
			winner_cells.push_back(cell);
		else:
			other_cells.push_back(cell)
	
	var tween = get_tree().create_tween()
	
	for cell in other_cells:
		tween.tween_property(cell, "modulate:a", 0.0, 0.05);
	
	var screen_center = Vector2(get_viewport().size / 2)
	
	for cell in winner_cells:
		var center_position = screen_center - cell.size / 2;
		tween.parallel().tween_property(cell, "global_position", center_position, 0.3).set_trans(Tween.TRANS_SINE)
		
	for cell in winner_cells:
		tween.parallel().tween_property(cell, "position:y", 70, 0.3)
		
	await tween.finished;

func change_board_visibility(visibility: Visibility):
	var speed = 4.0;
	
	match visibility:
		Visibility.VISIBLE:
			board_anim.play("appear", -1, speed)
		Visibility.HIDDEN:
			board_anim.play("appear", -1, -speed, true)
	
	await board_anim.animation_finished

func get_value(index: int):
	return _board[index]

func has_value(index: int):
	return get_value(index) != EMPTY;
	
func set_value(value: String, index: int):
	if has_value(index):
		print("board index '", index, "' it's already set");
		return;
		
	_board[index] = value;
	await _cells[index].draw_mark(value, get_player_color(), true)
	var winner = Utils.check_winner(_board, EMPTY);
	
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

func get_player():
	return _current_player;

func get_player_color():
	return get_color(_current_player)
	
func switch_player():
	_current_player = MARK_O if _current_player == MARK_X else MARK_X;
	
	if _mode == Mode.LOCAL:
		_my_player = _current_player;

func _go_to_main_menu():
	await change_board_visibility(Visibility.HIDDEN)
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func refresh_ui():
	for idx in _board.size():
		var value = _board[idx];
		var cell = _cells[idx];
		var color = get_color(value)
		cell.draw_mark(value,color)
		
	await on_waiting_move;

func _get_game_mode_text():
	match _mode:
		Mode.LOCAL:
			return "Mode: Local"
		Mode.CPU:
			var difficulty = (
				"Easy" if _difficulty == CpuPlayer.Difficulty.RANDOM
				else "Easy" if _difficulty == CpuPlayer.Difficulty.EASY
				else "Hard" if _difficulty == CpuPlayer.Difficulty.HARD
				else "Impossible" if _difficulty == CpuPlayer.Difficulty.IMPOSSIBLE
				else "" # unreachable
			)
			
			return "Mode: CPU (%s)" % difficulty;
		Mode.ONLINE:
			return "Mode: Online"

func get_peer_ids() -> Array[int]:
	var peer_ids : Array[int] = [];
	
	for player in _players.values():
		if player is OnlinePlayer:
			peer_ids.push_back(player.peer_id)
	
	return peer_ids;

func print_board():
	print("=== ", multiplayer.multiplayer_peer.get_unique_id())
	print("=== ", _board.slice(0, 3))
	print("=== ", _board.slice(3, 6))
	print("=== ", _board.slice(6, 9))
	
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
		
		_players[player] = OnlinePlayer.new(player_peer_id, player_move_rpc)
		
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
