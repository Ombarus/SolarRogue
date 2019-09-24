extends "res://scripts/GUI/GUILayoutBase.gd"

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	
	
func Ok_Callback():
	get_node("base").disabled = true
	BehaviorEvents.emit_signal("OnPopGUI")
		
	
func Init(init_param):
	get_node("base").disabled = false
	
