extends Control

@onready var play_local_btn: Button = $Menu/PlayLocalButton;
@onready var play_cpu_menu: MenuButton = $Menu/PlayCPUButton;
@onready var play_online_btn: Button = $Menu/PlayOnlineButton;

func _ready():
	play_local_btn.pressed.connect(_on_play_local)
	play_cpu_menu.get_popup().id_pressed.connect(_on_play_vs_cpu)
	play_online_btn.pressed.connect(_on_play_online)

func _on_play_local():
	_load_scene(Constants.GameMode.LOCAL)
	
func _on_play_vs_cpu(difficulty: CpuPlayer.Difficulty):
	_load_scene(Constants.GameMode.CPU, difficulty)
	
func _on_play_online():
	_load_scene(Constants.GameMode.ONLINE);

func _load_scene(mode: Constants.GameMode, difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.NORMAL):
	Application.game_mode = mode;
	Application.difficulty = difficulty;
	
	match mode:
		Constants.GameMode.LOCAL, Constants.GameMode.CPU:
			get_tree().change_scene_to_file("res://ui/scenes/local_game.tscn")
		Constants.GameMode.ONLINE:
			get_tree().change_scene_to_file("res://ui/scenes/online_game.tscn")
