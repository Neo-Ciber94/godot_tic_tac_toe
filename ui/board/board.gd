extends Control

class_name Board;

@onready var grid = $Grid;
@onready var container = $Container;
@onready var anim = $Grid/AnimationPlayer as AnimationPlayer;

signal on_click(slot: Slot, index: int);
signal on_hover(slot: Slot, index: int, is_over: bool);

func _ready():
	prepare_board(false)

func prepare_board(clear = true):
	var _slots = container.get_children() as Array[Slot];
	Utils.remove_all_signal_connections(on_click);
	Utils.remove_all_signal_connections(on_hover);
	
	if clear:
		for slot in _slots:
			slot.queue_free()
			
		var new_slot = preload("res://ui/board/slot.tscn").instantiate()
		container.add_child(new_slot);
	
	for idx in _slots.size():
		var slot = _slots[idx];
		
		slot.on_click.connect(func(this): on_click.emit(this, idx));
		slot.on_hover.connect(func(this, is_over): on_hover.emit(this, idx, is_over))

func show_board(visible: bool):
	const speed = 4.0;
	
	if visible:
		anim.play("appear", -1, speed)
	else:
		anim.play("appear", -1, -speed, true)
	
	await anim.animation_finished

func hide_slots(slots_indices: Array[int]):	
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
	
	var screen_center = Vector2(get_viewport().size / 2)
	
	for slot in winner_slots:
		var center_position = screen_center - slot.size / 2;
		tween.parallel().tween_property(slot, "global_position", center_position, 0.3).set_trans(Tween.TRANS_SINE)
		
	for slot in winner_slots:
		tween.parallel().tween_property(slot, "position:y", 70, 0.3)
		
	await tween.finished;
