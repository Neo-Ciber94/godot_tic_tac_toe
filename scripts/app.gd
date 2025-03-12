class_name Application;
extends RefCounted;

static var game_mode: Constants.GameMode = Constants.GameMode.LOCAL;
static var difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.RANDOM;
		
static func is_server() -> bool:
	return OS.get_cmdline_args().has("--server");

static func get_turn_timeout_seconds() -> int:
	const default_turn_timeout_seconds = 60;
	const env_name = "TURN_TIMEOUT_SECONDS";
	
	var value = Env.get_int(env_name, default_turn_timeout_seconds);
	
	if value <= 0:
		return default_turn_timeout_seconds;
		
	return value;

static var server_host: String:
	get:
		if OS.has_environment("HOST"):
			return Env.get_string("HOST", "127.0.0.1");
		
		return ProjectSettings.get_setting("environment/network/host", "127.0.0.1")
	
static var server_port: int:
	get:
		if is_server():
			return Env.get_int("PORT", 7000);
		else:
			if OS.has_environment("PORT"):
				return Env.get_int("PORT", 7000);
				
			return ProjectSettings.get_setting("environment/network/port", 7000) 
		
static var server_max_players: int:
	get:
		return Env.get_int("MAX_PLAYERS", 128)
