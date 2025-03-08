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
	
func to_json() -> String:
	return  JSON.stringify({
		"indices": _indices,
		"value": _value,
		"state": _state
	})
	
static func from_json(json: String) -> Winner:
	var obj = JSON.parse_string(json);
	var winner = Winner.new();
	var indices: Array[int] = [];
	indices.assign(obj.indices);
	
	winner._indices = indices;
	winner._value = obj.value;
	winner._state = obj.state;
	return winner;
