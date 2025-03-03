extends Control

@onready var play_local_btn: Button = $Menu/PlayLocalButton;
@onready var play_cpu_menu: MenuButton = $Menu/PlayCPUButton;
@onready var play_online_btn: Button = $Menu/PlayOnlineButton;
@onready var server_toggle_btn: CheckButton = $Menu/ServerToggle

func _ready():
	play_local_btn.pressed.connect(_on_play_local)
	play_cpu_menu.get_popup().id_pressed.connect(_on_play_vs_cpu)
	play_online_btn.pressed.connect(_on_play_online)
	server_toggle_btn.pressed.connect(func():
		GameConfig.is_server = server_toggle_btn.button_pressed;
		print("toggle: ",  server_toggle_btn.button_pressed)
	)

func _on_play_local():
	_load_scene(Game.Mode.LOCAL)
	
func _on_play_vs_cpu(difficulty: CpuPlayer.Difficulty):
	_load_scene(Game.Mode.CPU, difficulty)
	
func _on_play_online():
	_load_scene(Game.Mode.ONLINE);

func _load_scene(mode: Game.Mode, difficulty: CpuPlayer.Difficulty = CpuPlayer.Difficulty.RANDOM):
	GameConfig.game_mode = mode;
	GameConfig.difficulty = difficulty;
	get_tree().change_scene_to_file("res://ui/game.tscn")
