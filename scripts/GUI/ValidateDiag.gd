extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""

onready var _info : RichTextLabel = get_node("base/Info")
var _default_text : String = "Are you sure ?"

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	get_node("base").connect("OnCancelPressed", self, "Cancel_Callback")

func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
	
	if _callback_obj == null:
		return
		
	_callback_obj.call(_callback_method)
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
	
func Init(init_param):
	get_node("base").disabled = false
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	var info_text : String = _default_text
	if "custom_text" in init_param:
		info_text = init_param["custom_text"]
	
	_info.bbcode_text = "[center]%s[/center]" % info_text
