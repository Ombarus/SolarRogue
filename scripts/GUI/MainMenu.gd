extends Node


func _ready():
	OS.set_window_fullscreen(PermSave.get_attrib("settings.full_screen", false))
	OS.set_use_vsync(PermSave.get_attrib("settings.vsync", true))
	
	if Globals.is_mobile():
		Globals.selected_screen_size = Vector2(1280,720)
	else:
		Globals.selected_screen_size = Vector2(1920,1080)
	#Globals.selected_screen_size = Vector2(3840,2160)
	
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_EXPAND, Globals.selected_screen_size)
	
	#OS.set_window_size(Vector2(2208, 1242))
	var lang = PermSave.get_attrib("settings.lang")
	if lang != null:
		TranslationServer.set_locale(lang)
		BehaviorEvents.emit_signal("OnLocaleChanged")
	
	var cur_save = get_node("LocalSave").get_latest_save()
	get_node("CanvasLayer/SafeArea/MenuRootRoot/MenuRoot/HBoxContainer/MenuBtn/Continue").Disabled = cur_save == null or cur_save.empty()
	BehaviorEvents.call_deferred("emit_signal", "OnPushGUI", "MenuRoot", {})
	#BehaviorEvents.emit_signal("OnPushGUI", "MenuRoot", {})
	
	if Globals.is_ios():
		get_node("CanvasLayer/SafeArea/MenuRootRoot/MenuRoot/HBoxContainer/MenuBtn/Quit").visible = false

#func OnPopGUI_Callback():
#	var name_diag = get_node("PlayerName")
#	name_diag.visible = false
func _input(event):
	if event.is_action_released("screenshot"):
		var cur_datetime : Dictionary = OS.get_datetime()
		var save_file_path = "user://screenshot-%s%s%s-%s%s%s.png" % [cur_datetime["year"], cur_datetime["month"], cur_datetime["day"], cur_datetime["hour"], cur_datetime["minute"], cur_datetime["second"]]
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png(save_file_path)

func _on_newgame_pressed():
	var name_diag = get_node("CanvasLayer/SafeArea/PlayerNameRoot/PlayerName")
	BehaviorEvents.emit_signal("OnPushGUI", "PlayerName", {"callback_object":self, "callback_method":"_on_choose_name_callback"})
	

func _on_choose_name_callback(name):
	var cur_save = get_node("LocalSave").get_latest_save()
	PermSave.set_attrib("settings.default_name", name)
	if cur_save == null or cur_save.empty():
		_start_game(null)
	else:
		BehaviorEvents.emit_signal("OnPushGUI", "ValidateDiag", {"callback_object":self, "callback_method":"_start_game", "custom_text":"CONFIRM new game"})
		
		
func _start_game(param):
	get_node("LocalSave").delete_save()
	get_tree().change_scene("res://scenes/main.tscn")

func _on_Continue_pressed():
	get_tree().change_scene("res://scenes/main.tscn")


func _on_Quit_pressed():
	get_tree().quit()


func _on_Credits_pressed():
	BehaviorEvents.emit_signal("OnPushGUI", "Credits", {})


func _on_Setting_pressed():
	BehaviorEvents.emit_signal("OnPushGUI", "Settings", {})
