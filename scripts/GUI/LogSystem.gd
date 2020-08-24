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
		for i in range(_log_lines.size() - _lines_to_animate.size()):
			final_text += _log_lines[i] + "\n"
			
		final_text += _log_lines[-1]
		
		if _lines_to_animate.size() > 1:
			print("==========")
			print("animation : " + str(_lines_to_animate))
			print("log : " + str(_log_lines))
		
		var num_char : int = floor(_delta_acc / sec_between_char)
		_delta_acc -= sec_between_char * num_char
		var all_anim_done : bool = true
		for i in range(_lines_to_animate.size()):
			var cur_log : String = _log_lines[-(_lines_to_animate.size() - i)]
			var left_log : String = _lines_to_animate[i]
			if left_log.empty():
				final_text += cur_log + "\n"
			else:
				all_anim_done = false
				var to_add : int = num_char
				var bb_code := false
				while to_add > 0:
					var c = _lines_to_animate[i].left(1)
					_lines_to_animate[i] = _lines_to_animate[i].substr(1, -1)
					_log_lines[-(_lines_to_animate.size() - i)] += c
					
					if c == "[":
						bb_code = true
					elif c == "]":
						bb_code = false
					if bb_code == true:
						continue
					to_add -= 1
					
				final_text += _log_lines[-(_lines_to_animate.size() - i)] + "[color=lime]█[/color]\n"
				
		if all_anim_done:
			_lines_to_animate = []
			_current_state = LOG_ANIMATION_STATE.cursor_blink
		else:
			_window.content = final_text
			
		
	
	if _current_state == LOG_ANIMATION_STATE.cursor_blink:
		
		var final_text := ""
		for i in range(_log_lines.size()):
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
	_log_lines.push_back("")
	_current_state = LOG_ANIMATION_STATE.text_animation
	#_log_lines.push_back(Globals.mytr(l, fmt))
	#update_log()
	
	
func choose_random_line(text : Dictionary) -> String:
	var pondered = []
	for l in text:
		pondered.push_back({"text":l, "weight":text[l]})
	
	return MersenneTwister.rand_weight(pondered, "text", "weight", "Error loading random line")
	
