extends RefCounted

class_name Winner;

enum State { Won, None, Tie }

var _indices: Array[int] = [];
var _value: String;
var _state: State = State.None;

static func Won(indices: Array[int], value: String):
	var this = Winner.new();
	this._indices = indices;
	this._value = value;
	this._state = State.Won;
	return this;
	
static func None():
	return Winner.new();
	
static func Tie():
	var this = Winner.new();
	this._state = State.Tie;
	return this;

func get_indices():
	return _indices;
	
func get_value():
	return _value;
	
func is_finished():
	return _state != State.None;
	
func is_tie():
	return _state == State.Tie;

func _to_string() -> String:
	match _state:
		State.None:
			return "Winner(None)"
		State.Won:
			return "Winner(Won)"
		State.Tie:
			return "Winner(Tie)"
		_:
			return "Winner(..)"
	
