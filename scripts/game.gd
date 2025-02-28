extends Control

class_name Game;

enum Winner {
	NONE,
	YOU,
	OPPONENT,
	DRAW
}

signal declare_winner(winner: Winner)
signal start_game;

const PLACEHOLDER = "~"
const MARK_X = "x";
const MARK_O = "o";

var _slots: Array[String] = [];
var _turn_player = MARK_X
var _winner : Winner = Winner.NONE;

func _ready() -> void:
	restart_game()

func restart_game():
	_slots = [];
	_winner = Winner.NONE;

	for n in 9:
		_slots.append(PLACEHOLDER)
	
	start_game.emit()

func is_finished():
	return _winner != Winner.NONE;

func is_draw():
	return _winner == Winner.DRAW;

func get_turn_player():
	return _turn_player

func has_value(index: int):
		return _slots[index] != PLACEHOLDER
		
func set_value(index: int):
	if is_finished():
		return;

	_slots[index] = _turn_player;
	var has_winner = check_winner();
	print("has winner: ", has_winner);
	
	if(!has_winner):
		switch_turn_player()
	
func switch_turn_player():
	_turn_player = (
		MARK_O if _turn_player == MARK_X
		else MARK_X
	)

func set_winner(winner: Winner):
	if is_finished():
		return;
		
	_winner = winner;
	declare_winner.emit(winner)
	
func check_winner()-> bool:
	var filled_count = _slots.filter(func(x): return x != PLACEHOLDER).size()
	
	# At least 3 are needed to declare a winner
	if filled_count < 3:
		return false;
	
	# check horizontals
	var row_size = 3;
	
	for i in row_size:
		var start = i * row_size;
		var row = _slots.slice(start, start + row_size)
		
		if (row.all(func(n): return n != PLACEHOLDER)):	
			# If the 3 are set and are equals we have a winner
			if all_equals(row):
				set_winner(get_winner(row[0]))
				return true;
	
	# check verticals
	for i in 3:
		var a1 = _slots[i];
		var a2 = _slots[i + 3];
		var a3 = _slots[i + 6];
		var col = [a1, a2, a3];
		
		if (col.all(func(n): return n != PLACEHOLDER)):
			if all_equals(col):
				set_winner(get_winner(a1))
				return true;
				
	# check diagonals
	# 0 1 2
	# 3 4 5
	# 6 7 8
	var d1 = [_slots[0], _slots[4], _slots[8]];
	if (d1.all(func(n): return n != PLACEHOLDER)):
		if all_equals(d1):
			set_winner(get_winner(d1[0]))
			return true;
			
	var d2 = [_slots[2], _slots[4], _slots[6]];
	if (d2.all(func(n): return n != PLACEHOLDER)):
		if all_equals(d2):
			set_winner(get_winner(d2[0]))
			return true;

	if filled_count == _slots.size():
		set_winner(Winner.DRAW);
		return true;

	return false;

func get_winner(mark: String) -> Winner:
	return Winner.YOU if mark == MARK_X else Winner.OPPONENT;

func all_equals(arr: Array) -> bool:
	if arr.is_empty():
		return true;
		
	var prev = arr[0]
	for i in range(1, arr.size()):
		var x = arr[i];
		if x != prev:
			return false;
		
	return true;
