class_name GameModeLabel;
extends Label

func _ready():
	update_text(Application.game_mode, Application.difficulty)

func update_text(mode: Constants.GameMode, difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.RANDOM):
	text = _get_text_for_mode(mode, difficulty)

func _get_text_for_mode(mode: Constants.GameMode, difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.RANDOM):
	match mode:
		Constants.GameMode.LOCAL:
			return "Mode: Local"
		Constants.GameMode.CPU:
			var difficulty_text = (
				"Easy" if difficulty == CpuPlayer.Difficulty.RANDOM
				else "Easy" if difficulty == CpuPlayer.Difficulty.EASY
				else "Hard" if difficulty == CpuPlayer.Difficulty.HARD
				else "Impossible" if difficulty == CpuPlayer.Difficulty.IMPOSSIBLE
				else "" # unreachable
			)
			
			return "Mode: CPU (%s)" % difficulty_text;
		Constants.GameMode.ONLINE:
			return "Mode: Online"
