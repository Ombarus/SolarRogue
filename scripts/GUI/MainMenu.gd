extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	#BehaviorEvents.connect("OnPushGUI", self, "OnPushGUI_Callback")
	BehaviorEvents.connect("OnPopGUI", self, "OnPopGUI_Callback")

func OnPopGUI_Callback():
	var name_diag = get_node("MenuRoot/PlayerName")
	name_diag.visible = false

func _on_newgame_pressed():
	var name_diag = get_node("MenuRoot/PlayerName")
	name_diag.Init({"callback_object":self, "callback_method":"_on_choose_name_callback"})
	name_diag.visible = true
	

func _on_choose_name_callback(name):
	PermSave.set_attrib("settings.default_name", name)
	get_tree().change_scene("res://scenes/main.tscn")
	