class_name ExitButton;
extends Button

signal on_exit();

func _ready():
	pressed.connect(_on_exit);	
	
func _on_exit():
	on_exit.emit();
	get_tree().change_scene_to_file("res://ui/scenes/main_menu.tscn")
