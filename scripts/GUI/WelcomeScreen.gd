extends "res://scripts/GUI/GUILayoutBase.gd"

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	Globals.TutorialRef.emit_signal("StartTuto")
	get_node("base").disabled = true
		
	
func Init(init_param):
	get_node("base").disabled = false
	var player_name = init_param["player_name"]
	get_node("base").title = "Welcome %s..." % player_name
	
