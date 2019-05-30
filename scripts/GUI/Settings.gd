extends "res://scripts/GUI/GUILayoutBase.gd"

func _ready():
	get_node("base").connect("OnOkPressed", self, "Ok_Callback")
	
	
func Ok_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
		
	
func Init(init_param):
	var fs : bool = PermSave.get_attrib("settings.full_screen", false)
	get_node("base/VBoxContainer/FullScreen/CheckButton").pressed = fs
	

func _on_CheckButton_toggled(button_pressed):
	OS.set_window_fullscreen(button_pressed)
	PermSave.set_attrib("settings.full_screen", button_pressed)
