extends Label

class_name ServerIndicator;

static var _is_server: bool = false;

func _ready() -> void:
	_is_server = OS.get_cmdline_args().has("--server");
	hide();
	
	if _is_server:
		show()
	else:
		queue_free()

static func is_server() -> bool:
	return _is_server;
