extends "res://scripts/GUI/GUILayoutBase.gd"

var _default_info_text : String = ""

signal skip_pressed()
signal cancel_pressed()

func _ready():
	_default_info_text = get_node("Info").bbcode_text
	
func Init(init_param):
	if init_param != null and "info_text" in init_param:
		get_node("Info").bbcode_text = init_param.info_text
	else:
		get_node("Info").bbcode_text = _default_info_text
	
func _on_Skip_pressed():
	emit_signal("skip_pressed")


func _on_Cancel_pressed():
	emit_signal("cancel_pressed")
