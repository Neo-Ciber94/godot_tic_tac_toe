extends Control

@onready var play_local_btn: Button = $Menu/PlayLocalButton;
@onready var play_cpu_menu: MenuButton = $Menu/PlayCPUButton;
@onready var play_online_btn: Button = $Menu/PlayOnlineButton;

enum CpuLevel {
	EASY = 0,
	HARD = 1,
	IMPOSSIBLE = 2
}

func _ready():
	play_local_btn.pressed.connect(_on_play_local)
	play_cpu_menu.get_popup().id_pressed.connect(_on_play_vs_cpu)
	play_online_btn.pressed.connect(_on_play_online)

func _on_play_local():
	_load_scene(Game.Mode.LOCAL)
	
func _on_play_vs_cpu(level: CpuLevel):
	var cpu_level = (
		CpuPlayer.PlayStyle.RANDOM if level == CpuLevel.EASY
		else CpuPlayer.PlayStyle.MAX if level == CpuLevel.HARD
		else CpuPlayer.PlayStyle.IMPOSSIBLE if level == CpuLevel.IMPOSSIBLE
		else CpuPlayer.PlayStyle.RANDOM
	);
	
	_load_scene(Game.Mode.CPU, cpu_level)
	
func _on_play_online():
	print("not implemented yet")

func _load_scene(mode: Game.Mode, cpu_level: CpuPlayer.PlayStyle = CpuPlayer.PlayStyle.RANDOM):
	GameConfig.game_mode = Game.Mode.LOCAL;
	GameConfig.cpu_level = cpu_level;
	get_tree().change_scene_to_file("res://ui/game.tscn")
	pass
