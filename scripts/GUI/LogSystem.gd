extends Node

enum LOG_ANIMATION_STATE {
	idle,
	text_animation,
	cursor_blink
}

export(int) var max_log = 100
export(String) var blinker = "[color=gray]~$>[/color]"
export(float) var sec_between_char = 0.02

var _current_state = LOG_ANIMATION_STATE.idle
var _log_lines := []
var _lines_to_animate := []
var _window
var _delta_acc := 0.0

var translator

func _ready():
	_window = get_node("LogWindow")
	BehaviorEvents.connect("OnLogLine", self, "OnLogLine_CallBack")
	
func _process(delta):
	if _current_state == LOG_ANIMATION_STATE.idle:
		return
		
	_delta_acc += delta
	if _current_state == LOG_ANIMATION_STATE.text_animation and _delta_acc < sec_between_char:
		return
		
	if _current_state == LOG_ANIMATION_STATE.text_animation:
		var final_text := ""
		for i in range(_log_lines.size() - 1):
			final_text += _log_lines[i] + "\n"
			
		if _log_lines.size() <= 0:
			_log_lines.push_back("")
			
		final_text += _log_lines[-1]
		
		var bb_code := false
		while _delta_acc >= sec_between_char:
			var c = _lines_to_animate[0].left(1)
			_lines_to_animate[0] = _lines_to_animate[0].substr(1, -1)
			final_text += c
			_log_lines[-1] += c
			
			if c == "[":
				bb_code = true
			elif c == "]":
				bb_code = false
			if bb_code == true:
				continue
				
			_delta_acc -= sec_between_char
			
			if _lines_to_animate[0].length() <= 0:
				_lines_to_animate.remove(0)
				final_text += "\n"
				_log_lines.push_back("")
			if _lines_to_animate.size() <= 0:
				_current_state = LOG_ANIMATION_STATE.cursor_blink
				break
		
		if _current_state == LOG_ANIMATION_STATE.text_animation:
			_window.content = final_text + "[color=lime]█[/color]"
	
	if _current_state == LOG_ANIMATION_STATE.cursor_blink:
		
		var final_text := ""
		for i in range(_log_lines.size()-1):
			final_text += _log_lines[i] + "\n"
			
		if _delta_acc <= 0.1:
			final_text += "[color=gray]~$>[/color]"
		elif _delta_acc <= 0.2:
			pass
		elif _delta_acc <= 0.3:
			final_text += "[color=gray]~$>[/color]"
		elif _delta_acc <= 0.6:
			pass
		elif _delta_acc <= 0.8:
			final_text += "[color=gray]~$>[/color]"
		elif _delta_acc <= 1.0:
			pass
		else:
			final_text += "[color=gray]~$>[/color]"
			_current_state = LOG_ANIMATION_STATE.idle
			_delta_acc = 0.0
			
		_window.content = final_text
		
	
func OnLogLine_CallBack(text, fmt=[]):
	if _log_lines.size() > max_log:
		_log_lines.pop_front()
		
	var l = text
	if typeof(text) == TYPE_DICTIONARY:
		l = choose_random_line(text)
	
	_lines_to_animate.push_back(Globals.mytr(l, fmt))
	_current_state = LOG_ANIMATION_STATE.text_animation
	#_log_lines.push_back(Globals.mytr(l, fmt))
	#update_log()
	
	
func choose_random_line(text : Dictionary) -> String:
	var pondered = []
	for l in text:
		pondered.push_back({"text":l, "weight":text[l]})
	
	return MersenneTwister.rand_weight(pondered, "text", "weight", "Error loading random line")
	
