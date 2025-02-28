extends Node

@onready var grid = $Container/GridContainer

const PLACEHOLDER = "~";
const COLOR_UNSET = Color(0, 0, 0, 0.5);
const COLOR_P1 = Color(1, 0, 0);
const COLOR_P2 = Color(0, 0, 1);
const MARK_X = "x";
const MARK_O = "o";

var _cells : Array[Cell] = [];
var _slots: Array[String] = [];
var _winner: Winner = Winner.None();
var _player = MARK_X;

func _ready() -> void:
	start_game();

func start_game():
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
		
func get_value(index: int):
	return _slots[index]

func has_value(index: int):
	return get_value(index) != PLACEHOLDER;

func is_finished():
	return _winner.is_finished()

func set_value(value: String, index: int):
	_cells[index].draw_mark(value, get_player_color())
	_slots[index] = value;

	var winner = Utils.check_winner(_slots, PLACEHOLDER);
			
	if winner.is_finished():
		_winner = winner;
		print("game finished")
	else:
		switch_player()

func get_player_mark():
	return _player;

func get_player_color():
	return COLOR_P1 if _player == MARK_X else COLOR_P2;
	
func switch_player():
	_player = MARK_O if _player == MARK_X else MARK_X;

func _connect_to_signals(cell: Cell, index: int):
	cell.on_hover.connect(func(cell, is_over): on_cell_hover(cell, is_over, index))
	cell.on_click.connect(func(cell): on_cell_click(cell, index))

func on_cell_hover(cell: Cell, is_over: bool, index: int):
	if has_value(index) || is_finished():
		return;
	
	print("hover: ", index);
			
	if is_over:
		var mark = get_player_mark()
		var color = get_player_color();
		color.a = 0.5;
		cell.draw_mark(mark, color)
	else:
		cell.draw_mark(PLACEHOLDER, COLOR_UNSET)
	
func on_cell_click(cell: Cell, index: int):
	print("click: ", index);
	
	if has_value(index) || is_finished():
		return;
	
	set_value(get_player_mark(), index);
