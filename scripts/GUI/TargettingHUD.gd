extends "res://scripts/GUI/GUILayoutBase.gd"

var _default_info_text : String = ""
onready var _info = get_node("Info")
onready var _skip = get_node("Skip")

signal skip_pressed()
signal cancel_pressed()

func _ready():
	_default_info_text = _info.bbcode_text
	
func Init(init_param):
	if init_param != null and "info_text" in init_param:
		_info.bbcode_text = init_param.info_text
	else:
		_info.bbcode_text = Globals.mytr(_default_info_text)
	
	if init_param != null and "show_skip" in init_param:
		_skip.visible = init_param.show_skip
	
func _on_Skip_pressed():
	emit_signal("skip_pressed")


func _on_Cancel_pressed():
	emit_signal("cancel_pressed")
