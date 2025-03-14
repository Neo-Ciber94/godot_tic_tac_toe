class_name GameModeLabel;
extends Label

func _ready():
	update_text(Application.game_mode, Application.difficulty)

func update_text(mode: Constants.GameMode, difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.NORMAL):
	text = _get_text_for_mode(mode, difficulty)

func _get_text_for_mode(mode: Constants.GameMode, difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.NORMAL):
	match mode:
		Constants.GameMode.LOCAL:
			return "Mode: Local"
		Constants.GameMode.CPU:
			var difficulty_name: String = CpuPlayer.Difficulty.find_key(difficulty);
			var difficulty_text = difficulty_name.capitalize()
			return "Mode: CPU (%s)" % difficulty_text;
		Constants.GameMode.ONLINE:
			return "Mode: Online"
