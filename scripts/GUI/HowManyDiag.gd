extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""

onready var _selector = get_node("base/Selector")
onready var _info = get_node("base/Info")

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Cancel_Callback")

func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
	if _callback_obj == null:
		return
		
	var val = get_node("base/Selector").value
	_callback_obj.call(_callback_method, val)
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	
func Init(init_param):
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	_selector.min_value = init_param["min_value"]
	_selector.max_value = init_param["max_value"]
	
	_info.bbcode_text = "[center]" + str(_selector.value) + " / " + str(_selector.max_value) + "[/center]"
	

func _on_Selector_value_changed(value):
	var max_v = _selector.max_value
	_info.bbcode_text = "[center]" + str(value) + " / " + str(max_v) + "[/center]"
