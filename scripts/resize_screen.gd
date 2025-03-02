extends Node;

const SMALL_SCREEN_WIDTH = 800;
const SMALL_SCREEN_FACTOR = 1.8;

@onready var viewport = get_viewport()

var minimum_size = Vector2(1280, 720)

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_resize)
	_on_viewport_resize();

func _on_viewport_resize():
	var window_size = DisplayServer.window_get_size()
	var scale_factor = get_scale_factor(window_size)
	get_tree().root.content_scale_factor = scale_factor;

func get_scale_factor(window_size: Vector2):
	if window_size < minimum_size:
		var factor =  window_size.x / minimum_size.x
		
		if window_size.x < SMALL_SCREEN_WIDTH:
			return factor * SMALL_SCREEN_FACTOR;
		
		return factor;
	else:
		return 1
