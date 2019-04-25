extends Node

var _gui_list = {}
var _stack = []

func _ready():
	BehaviorEvents.connect("OnGUILoaded", self, "OnGUILoaded_Callback")
	BehaviorEvents.connect("OnPushGUI", self, "OnPushGUI_Callback")
	BehaviorEvents.connect("OnPopGUI", self, "OnPopGUI_Callback")
	BehaviorEvents.connect("OnPlayerCreated", self, "OnPlayerCreated_Callback")

func OnPlayerCreated_Callback(player):
	BehaviorEvents.disconnect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	# push default UI (might be some main menu or splash screen one day)
	BehaviorEvents.call_deferred("emit_signal", "OnPushGUI", "HUD", null)
	if not File.new().file_exists("user://savegame.save"):
		var player_name = player.get_attrib("player_name")
		BehaviorEvents.call_deferred("emit_signal", "OnPushGUI", "WelcomeScreen", {"player_name":player_name})

func OnGUILoaded_Callback(name, obj):
	_gui_list[name] = obj
	obj.visible = false
	
func OnPushGUI_Callback(name, init_param):
	#TODO: animate ?
	#TODO: make sure Layout is not already in stack
	_gui_list[name].visible = true
	_gui_list[name].Init(init_param)
	if _stack.size() > 0:
		_gui_list[_stack[-1]].call_deferred("OnFocusLost")
	_stack.push_back(name)
	
func OnPopGUI_Callback():
	print("Pop " + _stack[-1])
	_gui_list[_stack[-1]].visible = false
	_stack.pop_back()
	if _stack.size() > 0:
		_gui_list[_stack[-1]].call_deferred("OnFocusGained")