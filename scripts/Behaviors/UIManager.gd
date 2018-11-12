extends Node

var _gui_list = {}
var _stack = []

func _ready():
	BehaviorEvents.connect("OnGUILoaded", self, "OnGUILoaded_Callback")
	BehaviorEvents.connect("OnPushGUI", self, "OnPushGUI_Callback")
	BehaviorEvents.connect("OnPopGUI", self, "OnPopGUI_Callback")
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")

func OnLevelLoaded_Callback():
	BehaviorEvents.disconnect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	# push default UI (might be some main menu or splash screen one day)
	BehaviorEvents.call_deferred("emit_signal", "OnPushGUI", "HUD")

func OnGUILoaded_Callback(name, obj):
	_gui_list[name] = obj
	obj.visible = false
	
func OnPushGUI_Callback(name):
	#TODO: animate ?
	_gui_list[name].visible = true
	_stack.push_back(name)
	
func OnPopGUI_Callback():
	_gui_list[_stack[-1]].visible = false
	_stack.pop_back()