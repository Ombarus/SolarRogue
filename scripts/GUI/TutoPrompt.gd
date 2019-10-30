extends "res://scripts/GUI/GUILayoutBase.gd"

onready var _text : RichTextLabel = get_node("base/Content")
onready var _title : MyWindow = get_node("base")

var _callback_obj : Node = null
var _callback_method := ""

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	
	
func Ok_Callback():
	if _callback_obj != null:
		_callback_obj.call(_callback_method)
	BehaviorEvents.emit_signal("OnPopGUI")
	get_node("base").disabled = true
		
	
func Init(init_param):
	get_node("base").disabled = false
	_text.bbcode_text = init_param.text
	_title.title = init_param.title
	if "callback_object" in init_param:
		_callback_obj = init_param.callback_object
		_callback_method = init_param.callback_method
	
