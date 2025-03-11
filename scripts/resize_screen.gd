extends Node

@onready var viewport := get_viewport()

const LARGE_VIEWPORT = Vector2(1280, 720)
const MEDIUM_VIEWPORT = Vector2(720, 1280)

func _ready() -> void:
	get_tree().root.size_changed.connect(_adjust_viewport)
	_adjust_viewport()

func _adjust_viewport() -> void:
	var screen_size = DisplayServer.window_get_size()
	
	if screen_size.x > screen_size.y:
		get_tree().root.content_scale_size = LARGE_VIEWPORT;
	else:
		get_tree().root.content_scale_size  = MEDIUM_VIEWPORT;
