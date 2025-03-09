extends Label

class_name ServerIndicator;

func _ready() -> void:
	hide();
	
	if Application.is_server():
		show()
	else:
		queue_free()
