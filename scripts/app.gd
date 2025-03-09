class_name Application;
extends RefCounted;

static var game_mode: Constants.GameMode = Constants.GameMode.LOCAL;
static var difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.RANDOM;

static func is_server() -> bool:
	return OS.get_cmdline_args().has("--server");
