extends Node

@onready var _time: Label = $Time;
@onready var _start_btn: Button = $Actions/StartButton;
@onready var _restart_btn: Button = $Actions/RestartButton;
@onready var _stop_resume_btn: Button = $Actions/StopResumeButton;
@export var duration: int = 120;

var _countdown: Countdown;

func _ready():
	_countdown = Countdown.new();
	_countdown.duration = duration;
	_countdown.on_update.connect(_on_update);
	_countdown.on_timeout.connect(_on_timeout);
	add_child(_countdown)
	
	_start_btn.pressed.connect(_on_click_start);
	_restart_btn.pressed.connect(_on_click_restart)
	_stop_resume_btn.pressed.connect(_on_click_stop_resume)

func _on_click_start():
	_countdown.start()
	_stop_resume_btn.text = "Stop"
	
func _on_click_restart():
	_countdown.restart()
	_stop_resume_btn.text = "Stop"
	
func _on_click_stop_resume():
	if _countdown.is_stopped():
		_countdown.resume();
		_stop_resume_btn.text = "Stop"
	else:
		_countdown.stop();
		_stop_resume_btn.text = "Resume";
	
func _on_update(remaining_seconds: int):
	print("_on_update: ", remaining_seconds)
	var minutes: int = floor(remaining_seconds / 60);
	var seconds: int = remaining_seconds % 60;
	_time.text = "%02d:%02d" % [minutes, seconds]
	
func _on_timeout():
	print("_on_timeout")
	_time.add_theme_color_override("font_color", Color.RED)
