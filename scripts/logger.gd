class_name Logger;
extends Node

enum LogLevel {
	DEBUG,
	INFO,
	WARN,
	ERROR
}

const FORMATS = {
	DEFAULT = "{timestamp} [{level}] ",
	SIMPLE = "[{level}] "
}

static var min_level: LogLevel = LogLevel.DEBUG;
static var enabled = true;
static var log_format_string = FORMATS.DEFAULT;
static var colored = true;
static var use_push_error = false;
static var use_push_warning = false;

static func debug(message: Variant, additional: Variant = null) -> void:
	_log(LogLevel.DEBUG, message, additional)

static func info(message: Variant, additional: Variant = null) -> void:
	_log(LogLevel.INFO, message, additional)
	
static func warn(message: Variant, additional: Variant = null) -> void:
	_log(LogLevel.WARN, message, additional)
	
static func error(message: Variant, additional: Variant = null) -> void:
	_log(LogLevel.ERROR, message, additional)

static func _log(level: LogLevel, message: Variant, additional: Variant = null) -> void:
	if enabled == false || level < min_level:
		return;

	var leading = log_format_string.format({
		timestamp = Time.get_datetime_string_from_system(true),
		level = _get_log_level_str(level).rpad(5),
	})
	
	var args = [leading, message]
	
	if additional != null:
		args.push_back(additional)

	var log_function = _get_log_function(level);
	
	if log_function.can_color:
		var color = _get_log_level_color(level);
		args.push_front("[color=%s]" % color.to_html());
		args.push_back("[/color]");

	log_function.print.callv(args)


static func _get_log_function(level: LogLevel) -> Dictionary:
	if use_push_error && level == LogLevel.ERROR:
		return { print = push_error, can_color = false };
	elif use_push_warning && level == LogLevel.WARN:
		return { print = push_warning, can_color = false }
	else:
		if colored:
			return { print = print_rich, can_color = true }
		else:
			return { print = print, can_color = true }
	
static func _get_log_level_color(level: LogLevel) -> Color:
	match level:
		LogLevel.DEBUG:
			return Color.GRAY;
		LogLevel.INFO:
			return Color.CYAN;
		LogLevel.WARN:
			return Color.YELLOW;
		LogLevel.ERROR:
			return Color.RED;
		_:
			return Color.WHITE; 

static func _get_log_level_str(level: LogLevel) -> String:
	match level:
		LogLevel.DEBUG:
			return "DEBUG"
		LogLevel.INFO:
			return "INFO"
		LogLevel.WARN:
			return "WARN"
		LogLevel.ERROR:
			return "ERROR"
		_:
			return "NONE"	
