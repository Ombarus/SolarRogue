extends Node

var _log_lines = []
var _window

func _ready():
	_window = get_node("LogWindow")
	BehaviorEvents.connect("OnLogLine", self, "OnLogLine_CallBack")
	
func OnLogLine_CallBack(text):
	_log_lines.push_back(text)
	update_log()

func update_log():
	var final_text = ""
	for line in _log_lines:
		final_text += line + "\n"
		
	_window.content = final_text