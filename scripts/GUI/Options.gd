extends "res://scripts/GUI/GUILayoutBase.gd"

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	
		
func Init(init_param):
	pass
	

func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")

func _on_Save_pressed():
	Globals.LevelLoaderRef.SaveState(Globals.LevelLoaderRef.GetCurrentLevelData())
	BehaviorEvents.emit_signal("OnLogLine", "Game saved")


func _on_Suicide_pressed():
	BehaviorEvents.emit_signal("OnPushGUI", "ValidateDiag", {"callback_object":self, "callback_method":"On_Suicide_Confirmed_Callback", "custom_text":"Are you sure ?\nThe Savegame will be deleted"})


func _on_SaveAndQuit_pressed():
	_on_Save_pressed()
	get_tree().quit()

func On_Suicide_Confirmed_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPlayerDeath")

func _on_Settings_pressed():
	BehaviorEvents.emit_signal("OnPushGUI", "Settings", {})
