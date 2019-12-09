extends Node
class_name ShortcutManager

var _current_shortcut_dict : Dictionary = {}
var _shortcut_stack : Array = []
var _last_unicode = 0

func Add(key, obj, method, onpress=false):
	#if key in _current_shortcut_dict:
	#	var error_str = "********OVERRIDING SHORTCUT. %s IS ALREADY REGISTERED TO METHOD %s BUT TRYING TO ADD METHOD %s********"
	#	error_str = error_str % [key, _current_shortcut_dict[key].method, method]
	#	print(error_str)
	#var debug_str = "Register key %s to %s.%s"
	#debug_str = debug_str % [str(key), obj.name, method]
	#print(debug_str)
	if not key in _current_shortcut_dict:
		_current_shortcut_dict[key] = []
	_current_shortcut_dict[key].push_back({"obj":obj, "method":method, "onpress":onpress})
	
func Remove(key, obj, method):
	for l in _shortcut_stack:
		if key in l and l[key].obj == obj and l[key].method == method:
			l.erase(key)
			
	if key in _current_shortcut_dict and _current_shortcut_dict[key].obj == obj and _current_shortcut_dict[key].method == method:
		_current_shortcut_dict.erase(key)
		
func Enable(key, obj, method, isEnabled):
	#var debug_str = "Enable key %s to %s.%s : %s"
	#debug_str = debug_str % [str(key), obj.name, method, isEnabled]
	#print(debug_str)
	
	if key in _current_shortcut_dict:
		for shortcut in _current_shortcut_dict[key]:
			if shortcut.obj == obj and shortcut.method == method:
				shortcut["enabled"] = isEnabled
	
func _unhandled_input(event):
	if event is InputEventKey and event.pressed == true:
		if event.unicode != 0:
			_last_unicode = PoolByteArray([event.unicode]).get_string_from_utf8()
		else:
			_last_unicode = ""
	
	if event is InputEventKey && event.pressed == true:
		if _last_unicode in _current_shortcut_dict:
			for shortcut in _current_shortcut_dict[_last_unicode]:
				if shortcut.onpress == true and (not "enabled" in shortcut or shortcut.enabled == true):
					var obj : Node = shortcut.obj
					var method : String = shortcut.method
					obj.call(method)
		if event.scancode in _current_shortcut_dict:
			for shortcut in _current_shortcut_dict[event.scancode]:
				if shortcut.onpress == true and (not "enabled" in shortcut or shortcut.enabled == true):
					var obj : Node = shortcut.obj
					var method : String = shortcut.method
					obj.call(method)
					
					
	if event is InputEventKey && event.pressed == false:
		#print("unhandled input " + _last_unicode)
		if _last_unicode in _current_shortcut_dict:
			for shortcut in _current_shortcut_dict[_last_unicode]:
				if not "enabled" in shortcut or shortcut.enabled == true:
					var obj : Node = shortcut.obj
					var method : String = shortcut.method
					obj.call(method)
			
		if event.scancode in _current_shortcut_dict:
			for shortcut in _current_shortcut_dict[event.scancode]:
				if not "enabled" in shortcut or shortcut.enabled == true:
					var obj : Node = shortcut.obj
					var method : String = shortcut.method
					obj.call(method)
			

func _ready():
	BehaviorEvents.connect("OnAddShortcut", self, "Add")
	BehaviorEvents.connect("OnRemoveShortcut", self, "Remove")
	BehaviorEvents.connect("OnPushGUI", self, "OnPushGUI_Callback")
	BehaviorEvents.connect("OnPopGUI", self, "OnPopGUI_Callback")
	BehaviorEvents.connect("OnEnableShortcut", self, "Enable")
	
func OnPushGUI_Callback(name, init_param):
	_shortcut_stack.push_back(_current_shortcut_dict)
	_current_shortcut_dict = {}
	
func OnPopGUI_Callback():
	_current_shortcut_dict = _shortcut_stack[-1]
	_shortcut_stack.pop_back()
