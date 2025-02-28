extends RefCounted

class_name Winner;

var _indices: Array[int] = [];
var _value: String;
var _is_tie: bool = false;

static func Won(indices: Array[int], value: String):
	var this = Winner.new();
	this._indices = indices;
	this._value = value;
	return this;
	
static func None():
	return Winner.new();
	
static func Tie():
	var this = Winner.new();
	this._tie = true;
	return this;

func get_indices():
	return _indices;
	
func get_value():
	return _value;
	
func is_finished():
	return !get_indices().is_empty() || is_tie()
	
func is_tie():
	return _is_tie;
