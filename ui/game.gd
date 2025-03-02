extends Node
class_name Game;

@onready var grid = $Board/GridContainer
@onready var board = $Board;
@onready var board_grid = $Board/Grid
@onready var board_anim: AnimationPlayer = $Board/Grid/AnimationPlayer;
@onready var result_message: ResultMessage = $ResultMessage;
@onready var exit_btn : Button = $ExitButton;
	
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
var _is_first = true;
var _is_playing = false;

@export var _mode = GameConfig.game_mode;
@export var cpu_style = GameConfig.cpu_level;

signal waiting;
signal on_game_over;
	
var _players = {}
var current_player = MARK_X
	
func _ready() -> void:
	exit_btn.pressed.connect(_go_to_main_menu)
	start_game();

func start_game():
	result_message.hide();
		
	setup_board()
	setup_players()	
	start_playing();
		
func setup_board():
	_cells = [];
	_board = [];
	
	grid.show();
	result_message.hide();
	
	for child in grid.get_children():
			child.queue_free()
			
	var cell_scene = preload("res://ui/cell.tscn");
			
	for idx in 9:
		var cell = cell_scene.instantiate();
		grid.add_child(cell);
		
		_board.push_back(EMPTY)
		_cells.push_back(cell);
		cell.draw_mark(EMPTY, COLOR_EMPTY);
		
		cell.on_hover.connect(func(this_cell, is_over): 
			on_cell_hover(this_cell, is_over, idx)	
		)

func reset_board():
	_players = {}
	_winner = Winner.None()
	board_grid.modulate.a = 1.0;

func on_cell_hover(cell: Cell, is_over: bool, index: int):
	if !can_hover(index):
		return;
			
	if is_over:
		var mark = get_player()
		cell.draw_mark(mark, Color(get_player_color(), 0.2))
	else:
		cell.draw_mark(EMPTY, COLOR_EMPTY)

func setup_players():
	var player_values = [MARK_X, MARK_O];
	current_player = player_values[0]
		
	match _mode:
		Mode.LOCAL:
			print("start vs local")
			_players[MARK_X] = HumanPlayer.new()
			_players[MARK_O] = HumanPlayer.new()
		Mode.CPU:
			print("start vs cpu")
			_players[MARK_X] = HumanPlayer.new()
			_players[MARK_O] = CpuPlayer.new(player_values[1], cpu_style)
		Mode.ONLINE:
			print("start vs online")
			
	add_players_to_scene();

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
		waiting.emit();
	
	player.on_move.connect(callable, Object.CONNECT_ONE_SHOT)
	player.next_move(_cells.duplicate(), _board.duplicate())
	
	if index.value == -1:
		await waiting;
	
	return index.value;

func start_playing():		
	# We show an initial delay at the first game
	if _is_first:
		_is_first = false;
		for child in board_grid.get_children():
			if child is Line2D:
				child.modulate.a = 0.0;

	await change_board_visibility(Visibility.VISIBLE);
	
	_is_playing = true;
	
	while(not _winner.is_finished()):
		var has_played = { value = false };
		var player: Player = _players[current_player];
		print("current player: ", current_player)
		
		print("waiting for: ", current_player)
		var index = await make_move(player);
		print(current_player, " move to ", index);
		
		if has_value(index):
			print("illegal play")
			continue;
	
		await set_value(current_player, index);
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
		var color = COLOR_P1 if _winner.get_value() == MARK_X else COLOR_P2;
		result_message.change_text("winner!", color)
		
	result_message.show();

	# Wait to click for restart
	await result_message.on_click;
	remove_players_from_scene();
	reset_board()
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
			board_anim.play("appear", -1, 4)
		Visibility.HIDDEN:
			board_anim.play("appear", -1, -4, true)
	
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
	if _players[current_player] is not HumanPlayer:
		return false;
		
	if has_value(index):
		return false;

	return _is_playing && !is_game_over()

func is_game_over():
	return _winner.is_finished()

func get_player():
	return current_player;

func get_player_color():
	return get_color(current_player)
	
func switch_player():
	current_player = MARK_O if current_player == MARK_X else MARK_X;

func _go_to_main_menu():
	await change_board_visibility(Visibility.HIDDEN)
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func refresh_ui():
	for idx in _board.size():
		var value = _board[idx];
		var cell = _cells[idx];
		var color = get_color(value)
		cell.draw_mark(value,color)
		
	await waiting;

func print_board():
	print("=== ", _board.slice(0, 3))
	print("=== ", _board.slice(3, 6))
	print("=== ", _board.slice(6, 9))
	
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
