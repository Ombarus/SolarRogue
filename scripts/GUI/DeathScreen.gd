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
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	var success : bool = init_param["is_success"]
	
	get_node("tombstone/Name").text = init_param["player_name"]
	get_node("tombstone/Epitaph").text = init_param["epitaph"]
	get_node("base/Success2").bbcode_text = init_param["epitaph"]
	get_node("base/Success").text = init_param["message_success"]
	
	if success == true:
		get_node("tombstone").visible = false
		get_node("base/Earth").visible = true
		get_node("tombstone/Name").visible = false
		get_node("tombstone/Epitaph").visible = false
		get_node("base/Success").visible = true
		get_node("base/Success2").visible = true
		get_node("base").title = "You WON!"
	else:
		get_node("tombstone").visible = true
		get_node("base/Earth").visible = false
		get_node("tombstone/Name").visible = true
		get_node("tombstone/Epitaph").visible = true
		get_node("base/Success").visible = false
		get_node("base/Success2").visible = false
		get_node("base").title = "You are dead"
	
	
