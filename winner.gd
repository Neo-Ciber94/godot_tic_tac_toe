extends Label

@onready var anim = $AnimationPlayer;
@onready var game: Game = $"..";

const Winner = preload("res://game.gd").Winner;

var can_restart = false

func _on_game_start():
	can_restart = false;
	hide()
	
func _on_game_end(winner: Winner):
	print("winner declared: ", winner)
	show()
	anim.play("scale_pulse");

	match winner:
		Winner.YOU:
			text = "You win!"
		Winner.OPPONENT:
			text = "You lose!"
		Winner.DRAW:
			text = "Its a tie";
			
	await get_tree().create_timer(3.0).timeout
	can_restart = true;
	text = "Restart?"
	
func _input(event: InputEvent) -> void:
	if can_restart && event is InputEventMouseButton and event.pressed:
		print("Restart game")
		game.restart_game()
		
