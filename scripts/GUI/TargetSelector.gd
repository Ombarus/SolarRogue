extends "res://scripts/GUI/GUILayoutBase.gd"

var _callback_obj = null
var _callback_method = ""

onready var _base = get_node("base")
onready var _list = get_node("base/TargetList")

func _ready():
	_base.connect("OnCancelPressed", self, "Cancel_Callback")
	_list.connect("OnSelectionChanged", self, "SelectionChanged_Callback")

	
func Cancel_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	_base.disabled = true
	
	# reset content or we might end up with dangling references
	_list.Content = []
	
func SelectionChanged_Callback():
	if _callback_obj == null:
		return
		
	var selected_targets = []
	for data in _list.Content:
		if data.selected == true:
			selected_targets.push_back(data.key)
	if selected_targets.size() > 0:
		BehaviorEvents.emit_signal("OnPopGUI")
		_base.disabled = true
		_callback_obj.call(_callback_method, selected_targets)
		# reset content or we might end up with dangling references
		_list.Content = []
	
func Init(init_param):
	_base.disabled = false
	var targets = init_param["targets"]
	_callback_obj = init_param["callback_object"]
	_callback_method = init_param["callback_method"]
	
	var target_obj = []
	for item in targets:
		var icon = item.get_attrib("icon")
		if icon == null:
			target_obj.push_back({"name_id": item.get_attrib("name_id"), "key":item})
		else:
			target_obj.push_back({"name_id": item.get_attrib("name_id"), "key":item, "icon":item.get_attrib("icon")})
	_list.Content = target_obj
	
	#get_node("base").Content = result_string

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
