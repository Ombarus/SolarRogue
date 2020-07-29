extends Node

export(int) var max_log = 100

var _log_lines = []
var _window

var translator

func _ready():
	_window = get_node("LogWindow")
	BehaviorEvents.connect("OnLogLine", self, "OnLogLine_CallBack")
	
func OnLogLine_CallBack(text, fmt=[]):
	if _log_lines.size() > max_log:
		_log_lines.pop_front()
		
	var l = text
	if typeof(text) == TYPE_DICTIONARY:
		l = choose_random_line(text)
		
	_log_lines.push_back(Globals.mytr(l, fmt))
	update_log(true)
	
	
func choose_random_line(text : Dictionary) -> String:
	var pondered = []
	for l in text:
		pondered.push_back({"text":l, "weight":text[l]})
	
	return MersenneTwister.rand_weight(pondered, "text", "weight", "Error loading random line")
	

func update_log(animate=false):
	var old_lines = _log_lines.slice(0,-2)
	if _log_lines.size() <= 1:
		old_lines = []
	var new_line = _log_lines[-1]
	
	var final_text = ""
	for line in old_lines:
		final_text += line + "\n"
		
	if animate == false:
		final_text += new_line + "\n"
	else:
		var bb_code := false
		for c in new_line:
			final_text += c
			if c == "[":
				bb_code = true
			elif c == "]":
				bb_code = false
			if bb_code == true:
				continue
			_window.content = final_text + "[color=lime]█[/color]"
			yield(get_tree().create_timer(0.02), "timeout")
		final_text += "\n"
		
	_window.content = final_text
	_window.blink_cursor()
