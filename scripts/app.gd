class_name Application;
extends RefCounted;

static var game_mode: Constants.GameMode = Constants.GameMode.LOCAL;
static var difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.RANDOM;
		
static func is_server() -> bool:
	return OS.get_cmdline_args().has("--server");

static func get_turn_timeout_seconds() -> int:
	const default_turn_timeout_seconds = 60;
	const env_name = "GODOT_TURN_TIMEOUT_SECONDS";
	
	var value = Env.get_int(env_name, default_turn_timeout_seconds);
	
	if value <= 0:
		return default_turn_timeout_seconds;
		
	return value;

static var server_host: String:
	get:
		return ProjectSettings.get_setting("environment/network/host", "127.0.0.1")
	
static var server_port: int:
	get:
		if is_server():
			return Env.get_int("GODOT_SERVER_PORT", 7000);
		else:
			return ProjectSettings.get_setting("environment/network/port", 7000) 
		
static var server_max_players: int:
	get:
		return Env.get_int("GODOT_SERVER_MAX_PLAYERS", 1000)
