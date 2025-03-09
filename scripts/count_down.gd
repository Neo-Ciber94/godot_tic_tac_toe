# A count timer that counts from `duration` to `0` seconds and emit and signal when finished.
class_name Countdown;
extends Node

# States of the countdown.
enum State {
	STOPPED,
	RUNNING,
	FINISHED
}

# Emitted when the countdown starts, after each second passed and when finished.
signal on_update(remaining_seconds: int);

# Emitted when the countdown finishes.
signal on_timeout();

var _duration: int = 0;
var _seconds_passed: int = 0;
var _timer: Timer;
var _state := State.STOPPED;

# The countdown state.
var state: State:
	get:
		return _state;

# Gets the remaining seconds before end.
var remaining_seconds: int:
	get:
		return  _duration - _seconds_passed

# Sets or get the duration in seconds of the countdown
var duration: int:
	get:
		return _duration
	set(value):
		_duration = value;

# Gets the number of seconds passed.
var seconds_passed: int:
	get:
		return _seconds_passed;

# Starts the countdown timer.
func start():
	if is_running():
		return;
		
	_state = State.RUNNING;
	_seconds_passed = 0;
	_execute();
	
func _execute():	
	if _timer != null:
		_timer.queue_free()

	_timer = Timer.new();
	_timer.autostart = false;
	_timer.wait_time = 1.0;
	
	add_child(_timer);
	_timer.start()
	
	while(is_running()):
		on_update.emit(remaining_seconds)
		await _timer.timeout;
		_seconds_passed += 1;
		
		if _seconds_passed >= _duration:
			_timer.stop();
			_state = State.FINISHED;
			on_timeout.emit();
			break;
		
# Reset the countdown timer and start it again.
func restart():	
	if _timer != null:
		_timer.stop();
		
	_seconds_passed = 0;
	_state = State.STOPPED;
	start.call_deferred()
	
# Stops the countdown timer.
func stop():
	if _timer != null:
		_timer.stop();
		
	_state = State.STOPPED;
		
# If stopped resume the countdown timer.
func resume():
	if is_stopped():
		_state = State.RUNNING;
		_execute();

# Resets the countdown timer.
func reset():
	if _timer != null:
		_timer.stop();
		
	_seconds_passed = 0;
	_state = State.STOPPED;

# Returns whether if the countdown is running.
func is_running() -> bool:
	return _state == State.RUNNING;
	
# Returns whether if the countdown is stopped.
func is_stopped() -> bool:
	return _state == State.STOPPED;
	
# Returns whether if the countdown is finished.
func is_finished() -> bool:
	return _state == State.FINISHED;

func _to_string() -> String:
	return "Countdown(remaining_seconds = %s)" % remaining_seconds
