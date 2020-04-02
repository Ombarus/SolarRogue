extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""

onready var _info : RichTextLabel = get_node("base/Info")
onready var _base = get_node("base")
var _default_text : String = "Are you sure ?"

func _ready():
	_base.connect("OnOkPressed", self, "Ok_Callback")
	_base.connect("OnCancelPressed", self, "Cancel_Callback")

func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	_base.disabled = true
	
	if _callback_obj == null:
		return
		
	_callback_obj.call(_callback_method)
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	_base.disabled = true
	
func Init(init_param):
	_base.disabled = false
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	var info_text : String = _default_text
	if "custom_text" in init_param:
		info_text = init_param["custom_text"]
	
	_info.bbcode_text = "[center]%s[/center]" % Globals.mytr(info_text)
