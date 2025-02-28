extends RefCounted

class_name Utils;

static func check_winner(grid: Array[String], empty_marker: String)-> Winner:
	var filled_count = grid.filter(func(x): return x != empty_marker).size()
	
	# At least 3 are needed to declare a winner
	if filled_count < 3:
		return Winner.None();
	
	# check horizontals
	var row_size = 3;
	
	for i in row_size:
		var start = i * row_size;
		var end = start + row_size
		var row = grid.slice(start, end);
		
		if (row.all(func(n): return n != empty_marker)):	
			# If the 3 are set and are equals we have a winner
			if all_equals(row):
				var indices = arrayOfRange(start, end);
				print(indices);
				return Winner.Won(indices, grid[start]);
	
	# check verticals
	for i in 3:
		var a1 = grid[i];
		var a2 = grid[i + 3];
		var a3 = grid[i + 6];
		var col = [a1, a2, a3];
		
		if (col.all(func(n): return n != empty_marker)):
			if all_equals(col):
				return Winner.Won([i, i +3, i + 6], a1);
				
	# check diagonals
	# 0 1 2
	# 3 4 5
	# 6 7 8
	var d1 = [grid[0], grid[4], grid[8]];
	if (d1.all(func(n): return n != empty_marker)):
		if all_equals(d1):
			return Winner.Won([0, 4, 8], grid[0])
			
	var d2 = [grid[2], grid[4], grid[6]];
	if (d2.all(func(n): return n != empty_marker)):
		if all_equals(d2):
			return Winner.Won([2, 4, 6], grid[2])

	# its a tie
	if filled_count == grid.size():
		return Winner.Tie()

	return Winner.None()

static func arrayOfRange(start: int, end: int) -> Array[int]:
	var arr : Array[int] = [];
	
	for n in range(start, end):
		arr.push_back(n)
	
	return arr;

static func all_equals(arr: Array) -> bool:
	if arr.is_empty():
		return true;
		
	var prev = arr[0]
	for i in range(1, arr.size()):
		var x = arr[i];
		if x != prev:
			return false;
		
	return true;
