extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	OS.set_window_fullscreen(true)
	#BehaviorEvents.connect("OnPushGUI", self, "OnPushGUI_Callback")
	#BehaviorEvents.connect("OnPopGUI", self, "OnPopGUI_Callback")
	
	get_node("MenuRoot/Continue").Disabled = not File.new().file_exists("user://savegame.save")
	BehaviorEvents.emit_signal("OnPushGUI", "MenuRoot", {})

#func OnPopGUI_Callback():
#	var name_diag = get_node("PlayerName")
#	name_diag.visible = false

func _on_newgame_pressed():
	var name_diag = get_node("PlayerName")
	BehaviorEvents.emit_signal("OnPushGUI", "PlayerName", {"callback_object":self, "callback_method":"_on_choose_name_callback"})
	

func _on_choose_name_callback(name):
	var save_game = Directory.new()
	save_game.remove("user://savegame.save")
	
	PermSave.set_attrib("settings.default_name", name)
	get_tree().change_scene("res://scenes/main.tscn")
	

func _on_Continue_pressed():
	get_tree().change_scene("res://scenes/main.tscn")


func _on_Quit_pressed():
	get_tree().quit()
