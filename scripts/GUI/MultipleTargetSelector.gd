extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""

onready var _base = get_node("base")
onready var _list = get_node("base/HBoxContainer/TargetList")

func _ready():
	_list.connect("OnSelectionChanged", self, "OnSelectionChanged_Callback")
	_base.connect("OnCancelPressed", self, "Cancel_Callback")
	_base.connect("OnOkPressed", self, "Ok_Callback")
	get_node("base/HBoxContainer/VBoxContainer/All").connect("pressed", self, "all_pressed_callback")
	get_node("base/HBoxContainer/VBoxContainer/None").connect("pressed", self, "none_pressed_callback")

func Ok_Callback():
	var selected_targets = []
	for data in _list.Content:
		if data.selected > 0:
			selected_targets.push_back(data)
			
	if selected_targets.size() > 0:
		_base.disabled = true
		_callback_obj.call(_callback_method, selected_targets)
#		# reset content or we might end up with dangling references
		_list.Content = []
	BehaviorEvents.emit_signal("OnPopGUI")
	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	_base.disabled = true
	
	# reset content or we might end up with dangling references
	_list.Content = []
	
func OnSelectionChanged_Callback():
	#TODO: Update labels with turn count and # of items
	var total_items = 0
	for data in _list.Content:
		total_items += data["selected"]
	get_node("base/HBoxContainer/VBoxContainer/ItemCount").text = Globals.mytr("Total: %d items", [total_items])
	get_node("base/HBoxContainer/VBoxContainer/TurnCount").text = Globals.mytr("Will take %d turns", [total_items])
	
func all_pressed_callback():
	var updated_content = _list.Content
	for data in updated_content:
		data["selected"] = data["count"]
	_list.UpdateContent(updated_content)
	OnSelectionChanged_Callback()
	
func none_pressed_callback():
	var updated_content = _list.Content
	for data in updated_content:
		data["selected"] = 0
	_list.UpdateContent(updated_content)
	OnSelectionChanged_Callback()
	
func Init(init_param):
	_base.disabled = false
	var targets = init_param["targets"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	var target_obj = []
	for item in targets:
		var icon = item["obj"][0].get_attrib("icon")
		var display_name = Globals.EffectRef.get_object_display_name(item["obj"][0])
		if icon == null:
			target_obj.push_back({"name_id": display_name, "key":item["obj"], "count":item["count"], "direction":item["direction"]})
		else:
			target_obj.push_back({"name_id": display_name, "key":item["obj"], "icon":item["obj"][0].get_attrib("icon"), "count":item["count"], "direction":item["direction"]})
				
	_list.Content = target_obj
