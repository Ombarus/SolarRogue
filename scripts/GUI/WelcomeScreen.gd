extends "res://scripts/GUI/GUILayoutBase.gd"

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
		
	
func Init(init_param):
	var player_name = init_param["player_name"]
	get_node("base").title = "Welcome %s..." % player_name
	
