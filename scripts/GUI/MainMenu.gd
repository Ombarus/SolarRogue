extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	OS.set_window_fullscreen(PermSave.get_attrib("settings.full_screen", false))
	OS.set_use_vsync(PermSave.get_attrib("settings.vsync", true))
	var lang = PermSave.get_attrib("settings.lang")
	if lang != null:
		TranslationServer.set_locale(lang)
		BehaviorEvents.emit_signal("OnLocaleChanged")
	#BehaviorEvents.connect("OnPushGUI", self, "OnPushGUI_Callback")
	#BehaviorEvents.connect("OnPopGUI", self, "OnPopGUI_Callback")
	
	var cur_save = get_node("LocalSave").get_latest_save()
	
	get_node("SafeArea/MenuRoot/MenuBtn/Continue").Disabled = cur_save == null or cur_save.empty()
	BehaviorEvents.emit_signal("OnPushGUI", "MenuRoot", {})
	
	if Globals.is_ios():
		get_node("SafeArea/MenuRoot/MenuBtn/Quit").visible = false

#func OnPopGUI_Callback():
#	var name_diag = get_node("PlayerName")
#	name_diag.visible = false

func _on_newgame_pressed():
	var name_diag = get_node("SafeArea/PlayerName")
	BehaviorEvents.emit_signal("OnPushGUI", "PlayerName", {"callback_object":self, "callback_method":"_on_choose_name_callback"})
	

func _on_choose_name_callback(name):
	get_node("LocalSave").delete_save()
	
	PermSave.set_attrib("settings.default_name", name)
	get_tree().change_scene("res://scenes/main.tscn")
	

func _on_Continue_pressed():
	get_tree().change_scene("res://scenes/main.tscn")


func _on_Quit_pressed():
	get_tree().quit()


func _on_Credits_pressed():
	BehaviorEvents.emit_signal("OnPushGUI", "Credits", {})


func _on_Setting_pressed():
	BehaviorEvents.emit_signal("OnPushGUI", "Settings", {})
