extends Player;

class_name CpuPlayer;

func next_move(cells: Array[Cell], board: Array[String]):
	print("cpu move")
	await delay_seconds(1);
	
	var index = get_next_random(board);
	print("cpu index: ", index)
	on_move.emit(index)

func get_next_random(board: Array[String]) -> int:
	var indices : Array[int] = [];
	
	for idx in board.size():
		var value = board[idx];
		
		if value == Game.EMPTY:
			indices.push_back(idx);
	
	assert(indices.size() > 0, "not more moves can be made");
	return indices.pick_random()

func delay_seconds(seconds: int):
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	timer.autostart = true
	add_child(timer)

	await timer.timeout
	remove_child(timer)
