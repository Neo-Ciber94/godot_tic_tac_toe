extends Control

class_name Board;

@onready var _grid = $Grid;
@onready var _container = $Container;
@onready var _anim = $Grid/AnimationPlayer as AnimationPlayer;

signal on_click(slot: Slot, index: int);
signal on_hover(slot: Slot, index: int, is_over: bool);

var _slots: Array[Slot] = [];

func _ready():
	hide_lines(); # ensure the initial state of the lines its with opacity 0
	prepare_board()

func prepare_board():	
	_slots = [];
	
	for child in _container.get_children():
		child.queue_free()
		
	var slot_scene = preload("res://ui/board/slot.tscn");
	
	for idx in range(9):
		var new_slot: Slot = slot_scene.instantiate()		
		_container.add_child(new_slot);
		_slots.push_back(new_slot)
		
		new_slot.on_click.connect(func(this): on_click.emit(this, idx));
		new_slot.on_hover.connect(func(this, is_over): on_hover.emit(this, idx, is_over))
	
func set_slot_value(idx: int, value: String, color: Color, animate: bool = true):
	var slot = _slots[idx];
	slot.set_value(value, color, animate)

func fill_slots(value: String, color: Color):
	for slot in _slots:
		slot.set_value(value, color)

func show_board(is_visible: bool):
	const speed = 4.0;
	
	if is_visible:
		_anim.play("appear", -1, speed)
	else:
		_anim.play("appear", -1, -speed, true)
	
	await _anim.animation_finished

func hide_lines():
	for child in _grid.get_children():
		if child is Line2D:
			child.modulate.a = 0;

func highlight_winner(slots_indices: Array[int] = []):	
	var winner_slots: Array[Slot] = [];
	var other_slots : Array[Slot] = [];

	for idx in _slots.size():
		var is_winner_idx = slots_indices.has(idx);
		var slot = _slots[idx]
		
		if is_winner_idx:
			winner_slots.push_back(slot);
		else:
			other_slots.push_back(slot)
	
	var tween = get_tree().create_tween()
	
	for slot in other_slots:
		tween.tween_property(slot, "modulate:a", 0.0, 0.05);
	
	var screen_center = Vector2(get_viewport().get_visible_rect().size / 2)
	
	for slot in winner_slots:
		var center_position = screen_center - slot.size / 2;
		tween.parallel().tween_property(slot, "global_position", center_position, 0.3).set_trans(Tween.TRANS_SINE)
		
	for slot in winner_slots:
		tween.parallel().tween_property(slot, "position:y", 70, 0.3)
		
	await tween.finished;
