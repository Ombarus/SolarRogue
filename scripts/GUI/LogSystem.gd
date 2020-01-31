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
		
	_log_lines.push_back(Globals.mytr(text, fmt))
	update_log()

func update_log():
	var final_text = ""
	for line in _log_lines:
		final_text += line + "\n"
		
	_window.content = final_text
