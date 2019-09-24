extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")

	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
	_callback_obj.call(_callback_method)
	
	
func Init(init_param):
	get_node("base").disabled = false
	var text = init_param["text"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	get_node("base/Content").bbcode_text = text
	
