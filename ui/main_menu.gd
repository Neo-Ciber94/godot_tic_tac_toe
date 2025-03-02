extends Control

@onready var play_local_btn: Button = $Menu/PlayLocalButton;
@onready var play_cpu_menu: MenuButton = $Menu/PlayCPUButton;
@onready var play_online_btn: Button = $Menu/PlayOnlineButton;

func _ready():
	play_local_btn.pressed.connect(_on_play_local)
	play_cpu_menu.get_popup().id_pressed.connect(_on_play_vs_cpu)
	play_online_btn.pressed.connect(_on_play_online)

func _on_play_local():
	_load_scene(Game.Mode.LOCAL)
	
func _on_play_vs_cpu(difficulty: CpuPlayer.Difficulty):
	_load_scene(Game.Mode.CPU, difficulty)
	
func _on_play_online():
	print("not implemented yet")

func _load_scene(mode: Game.Mode, difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.RANDOM):
	GameConfig.game_mode = mode;
	GameConfig.difficulty = difficulty;
	get_tree().change_scene_to_file("res://ui/game.tscn")
