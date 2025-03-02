extends RefCounted

class_name Utils;

const WIN_POSITIONS : Array = [
		# verticals
		[0, 1, 2],
		[3, 4, 5],
		[6, 7, 8],

		# horizontals
		[0, 3, 6],
		[1, 4, 7],
		[2, 5, 8],
		
		# diagonals
		[0, 4, 8],
		[2, 4, 6]
];

static func check_winner(board: Array[String], empty_marker: String) -> Winner:
	var filled_count = board.filter(func(x): return x != empty_marker).size()
	
	# At least 3 are needed to declare a winner
	if filled_count < 3:
		return Winner.None();
		
	for idx in WIN_POSITIONS.size():
		var indices : Array[int] = [];
		indices.assign(WIN_POSITIONS[idx]);
		
		var values = select_indices(board, indices);

		if values.has(empty_marker):
			continue;
		
		if all_equals(values):
			return Winner.Won(indices.duplicate(), values[0]);
	
	# All filled but not winner declared
	if filled_count == board.size():
		return Winner.Tie()
	
	return Winner.None()

static func select_indices(values: Array, indices: Array[int]) -> Array:
	var result = []
	
	for i in indices:
		var value = values[i];
		result.push_back(value)
	
	return result;

static func all_equals(arr: Array) -> bool: 
	if arr.is_empty():
		return true;
		
	var prev = arr[0]
	for i in range(1, arr.size()):
		var x = arr[i];
		if x != prev:
			return false;
		
	return true;
