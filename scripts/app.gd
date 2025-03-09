class_name Application;
extends RefCounted;

static var game_mode: Constants.GameMode = Constants.GameMode.LOCAL;
static var difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.RANDOM;
		
static func is_server() -> bool:
	return OS.get_cmdline_args().has("--server");
	
static var show_turn_timeout_on_remaining_seconds: int:
	get:
		return 30;

static func get_turn_timeout_seconds() -> int:
	const default_turn_timeout_seconds = 60;
	const env_name = "GODOT_TURN_TIMEOUT_SECONDS";
	
	var value = Env.get_int(env_name, default_turn_timeout_seconds);
	
	if value <= 0:
		return default_turn_timeout_seconds;
		
	return value;
