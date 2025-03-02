extends Node
class_name Game;

@onready var grid = $Board/GridContainer
@onready var dialog: Dialog = $Dialog;
@onready var board = $Board;
@onready var board_grid = $Board/Grid
@onready var board_anim: AnimationPlayer = $Board/Grid/AnimationPlayer;

enum Mode {
	LOCAL,
	CPU,
	ONLINE
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
var _mode = Mode.CPU;

signal waiting;
signal on_game_over;
	
var _players = {}
var current_player = {}
	
func _ready() -> void:
	start_game();

func start_game():
	dialog.hide();
		
	setup_board()
	setup_players()	
	start_playing();
		
func setup_board():
	_cells = [];
	_board = [];
	
	grid.show();
	dialog.hide();
	
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
	if has_value(index) || is_game_over() || !can_hover():
		return;
			
	if is_over:
		var mark = get_player()
		cell.draw_mark(mark, Color(get_player_color(), 0.5))
	else:
		cell.draw_mark(EMPTY, COLOR_EMPTY)

func setup_players():
	match _mode:
		Mode.LOCAL:
			print("start vs local")
			_players[MARK_X] = HumanPlayer.new()
			_players[MARK_O] = HumanPlayer.new()
		Mode.CPU:
			print("start vs cpu")
			_players[MARK_X] = HumanPlayer.new()
			_players[MARK_O] = CpuPlayer.new()
		Mode.ONLINE:
			print("start vs online")
			
	add_players_to_scene();
	current_player = { value = MARK_X }

func add_players_to_scene():
	add_child(_players[MARK_X]);
	add_child(_players[MARK_O]);
	
func remove_players_from_scene():
	remove_child(_players[MARK_X])
	remove_child(_players[MARK_O])
	
func start_playing():		
	board_anim.play("appear", -1, 4)
	await board_anim.animation_finished
	
	while(not _winner.is_finished()):
		var has_played = { value = false };
		var player: Player = _players[current_player.value];
		print("current player: ", current_player.value)

		var callable = Callable(func(idx): 
			if has_played.value: 
				return;
				
			if is_game_over():
				waiting.emit()
				return;
				
			has_played.value = true;
			
			print("player '", current_player.value, "' move to ", idx);
			set_value(current_player.value, idx);
			print("value set");
			waiting.emit()	
			print("done?")
		)

		print("winner? ", _winner);
		player.on_move.connect(callable)
		player.next_move(_cells.duplicate(), _board.duplicate());
		
		print("waiting for: ", current_player.value)
		await waiting;
		print("waiting done for player: ", current_player.value)

		print("== ", _board.slice(0, 3))
		print("== ", _board.slice(3, 6))
		print("== ", _board.slice(6, 9))
		
		player.on_move.disconnect(callable)
				
		if _winner.is_finished():
			break;
		else:
			switch_player()
	
	print("game its over")
	
	board_anim.play("appear", -1, -4, true)
	await hide_cells();
	
	# Show the winner dialog
	if _winner.is_tie():
		dialog.change_text("It's a tie", Color.BLACK);
	else:
		var color = COLOR_P1 if _winner.get_value() == MARK_X else COLOR_P2;
		dialog.change_text("winner!", color)
		
	dialog.show();

	# Wait to click for restart
	await dialog.on_click;
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


func get_value(index: int):
	return _board[index]

func has_value(index: int):
	return get_value(index) != EMPTY;
	
func set_value(value: String, index: int):
	if has_value(index):
		return;
		
	_board[index] = value;
	await _cells[index].draw_mark(value, get_player_color(), true)
	var winner = Utils.check_winner(_board, EMPTY);
	
	if winner.is_finished():
		print("finished: ", winner)
		_winner = winner;
		on_game_over.emit()

func can_hover():
	return _players[current_player.value] is HumanPlayer;

func is_game_over():
	return _winner.is_finished()

func get_player():
	return current_player.value;

func get_player_color():
	return COLOR_P1 if current_player.value == MARK_X else COLOR_P2;
	
func switch_player():
	current_player.value = MARK_O if current_player.value == MARK_X else MARK_X;
