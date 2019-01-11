extends Node

export(NodePath) var LogWindow
export(int) var day_length = 100
var log_window_ref
var action_list = []
var star_date_turn = 0
var star_date_minor = 0
var star_date_major = 0
var _disable = false

func _ready():
	log_window_ref = get_node(LogWindow)
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnUseAP", self, "OnUseAP_Callback")
	BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	
func OnRequestObjectUnload_Callback(obj):
	if obj.get_attrib("type") == "player":
		_disable = true
	action_list.erase(obj)

func OnUseAP_Callback(obj, amount):
	obj.modified_attributes["ap"] = true
	var index = action_list.find(obj)
	if index < 0:
		return
	
	action_list.remove(index)	
	obj.modified_attributes.action_point += amount
	Insert(obj, obj.modified_attributes.action_point)
	NormalizeAP()
	
	var obj_action = action_list[0]
	var top_ap = obj_action.modified_attributes.action_point
	for i in range(action_list.size()):
		var next_obj_action = action_list[i]
		var next_ap = next_obj_action.modified_attributes.action_point
		if next_ap != top_ap:
			break
		# at equal ap, player always go first
		if next_obj_action.get_attrib("type") == "player":
			obj_action = next_obj_action
			break
		
	# OnobjTurn triggers OnUseAp so this is circular.
	# The only reason it won't crash right away is that the player waits for input
	# using call_deferred should allow us to "queue" the OnObjTurn and do them in sequence (or even in parallel)
	self.call_deferred("validate_emit_OnObjTurn", obj_action)
	
func validate_emit_OnObjTurn(obj):
	# if object has been removed from list before it had a chance to act. Ignore it
	if action_list.find(obj) != -1 and _disable == false:
		BehaviorEvents.emit_signal("OnObjTurn", obj)

# Top action is always 0 AP. This way when we insert a new object it will be the first to act
func NormalizeAP():
	var top_ap = action_list[0].modified_attributes.action_point
	if top_ap == 0:
		return
		
	Globals.total_turn += top_ap
	Globals.last_delta_turn = top_ap
	
	for i in range(0,action_list.size()):
		action_list[i].modified_attributes.action_point -= top_ap
	star_date_turn += top_ap
	if star_date_turn >= 100.0:
		star_date_turn -= 100.0
		star_date_minor += 1
	if star_date_minor >= 100.0:
		star_date_minor -= 100.0
		star_date_major += 1
	UpdateLogTitle()

func UpdateLogTitle():
	if log_window_ref == null:
		return
	var title = "Log Stardate "
	title += str(int(star_date_major))
	title += "."
	title += str(int(star_date_minor))
	title += "."
	title += str(int(star_date_turn))
	log_window_ref.title = title

func OnObjectLoaded_Callback(obj):
	var attrib = obj.get_attrib("action_point")
	if obj.get_attrib("type") == "player":
		_disable = false
	if attrib != null:
		var start_point = attrib
		obj.set_attrib("action_point", start_point)
		Insert(obj, start_point)
		
	
func Insert(obj, action_point):
	for i in range(action_list.size()):
		if action_list[i].modified_attributes.action_point >= action_point:
			action_list.insert(i, obj)
			return
			
	action_list.push_back(obj)
	
	
#func _process(delta):
#	print(action_list)
	
