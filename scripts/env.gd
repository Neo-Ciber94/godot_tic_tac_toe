class_name Env;
extends RefCounted;

static func get_int(name: String, default_value: int) -> int:
	if not OS.has_environment(name):
		return default_value;
		
	var raw = OS.get_environment(name);
	
	if not raw.is_valid_int():
		return default_value;

	return raw.to_int();
	

static func get_bool(name: String, default_value: bool = false) -> bool:
	if not OS.has_environment(name):
		return default_value;
		
	var raw = OS.get_environment(name);
	
	if raw.to_lower() == "true":
		return true;
		
	if raw.to_lower() == "false":
		return false;
		
	return default_value;

static func get_string(name: String, default_value: String) -> String:
	if not OS.has_environment(name):
		return default_value;
		
	return OS.get_environment(name)
