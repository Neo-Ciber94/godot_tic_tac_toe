extends RefCounted;

class_name GameConfig;

static var game_mode: Game.Mode = Game.Mode.LOCAL;
static var difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.RANDOM;
static var is_server = OS.get_cmdline_args().has("--server");
