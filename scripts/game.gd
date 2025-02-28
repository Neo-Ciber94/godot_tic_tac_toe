extends Node

@onready var grid = $Container/GridContainer

enum Versus {
	SELF,
	CPU,
	ONLINE
}

const PLACEHOLDER = "~";
const MARK_X = "x";
const MARK_O = "o";

const COLOR_UNSET = Color(0, 0, 0, 0.5);
const COLOR_P1 = Color(1, 0, 0);
const COLOR_P2 = Color(0, 0, 1);

var _cells : Array[Cell] = [];
var _slots: Array[String] = [];
var _winner: Winner = Winner.None();
var _versus = Versus.SELF;

signal waiting;
signal on_game_over;
	
var _players = {
	MARK_X: HumanPlayer.new()
}

var current_player = {
	value = MARK_X
}
	
func _ready() -> void:
	start_game();

func start_game():
	setup_board()
	setup_players()
		
func setup_board():
	_cells = [];
	_slots = [];
	
	for child in grid.get_children():
			child.queue_free()
			
	var cell_scene = preload("res://scripts/cell.tscn");
			
	for idx in 9:
		var cell = cell_scene.instantiate();
		grid.add_child(cell);
		
		_slots.push_back(PLACEHOLDER)
		_cells.push_back(cell);
		cell.draw_mark(PLACEHOLDER, COLOR_UNSET);
		_connect_to_signals(cell, idx);
	
func setup_players():
	match _versus:
		Versus.SELF:
			start_vs_self()
		Versus.CPU:
			start_vs_cpu()
		Versus.ONLINE:
			start_vs_online();
	
func start_vs_self():
	_players[MARK_O] = HumanPlayer.new()
	
	var is_finished = { value = false }
	is_finished.value = false;
	
	on_game_over.connect(func():
		is_finished.value = true;
	)

	while(not is_finished.value):
		var has_played = false;
		var player: Player = _players[current_player.value];
		print("current player: ", current_player.value)
		
		var callable = Callable(func(idx): 
			if has_played: 
				return;
				
			has_played = true;

			set_value(current_player.value, idx);
			waiting.emit()	
		)

		player.on_move.connect(callable)
		player.player_move(_cells);
		
		await waiting;
		
		player.on_move.disconnect(callable)
		switch_player()
	
	print("game its over")
	
func start_vs_cpu():
	print("start vs cpu")
	
func start_vs_online():
	print("start vs online")
	
func get_value(index: int):
	return _slots[index]

func has_value(index: int):
	return get_value(index) != PLACEHOLDER;
	
func set_value(value: String, index: int):
	_cells[index].draw_mark(value, get_player_color())
	_slots[index] = value;
	
	var winner = Utils.check_winner(_slots, PLACEHOLDER);
	
	if winner.is_finished():
		print("finished: ", winner)
		_winner = winner;
		on_game_over.emit()

func is_game_over():
	return _winner.is_finished()

func get_player_mark():
	return current_player.value;

func get_player_color():
	return COLOR_P1 if current_player.value == MARK_X else COLOR_P2;
	
func switch_player():
	current_player.value = MARK_O if current_player.value == MARK_X else MARK_X;

func _connect_to_signals(cell: Cell, index: int):
	cell.on_hover.connect(func(cell, is_over): on_cell_hover(cell, is_over, index))

func on_cell_hover(cell: Cell, is_over: bool, index: int):
	if has_value(index) || is_game_over():
		return;
	
	#print("hover: ", index);
			
	if is_over:
		var mark = get_player_mark()
		var color = get_player_color();
		color.a = 0.5;
		cell.draw_mark(mark, color)
	else:
		cell.draw_mark(PLACEHOLDER, COLOR_UNSET)
