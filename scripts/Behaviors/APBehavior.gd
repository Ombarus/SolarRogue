extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var action_list = []

func _ready():
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnUseAP", self, "OnUseAP_Callback")

func OnUseAP_Callback(obj, amount):
	print("Use AP ", amount)
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
		if next_obj_action.base_attributes.type == "player":
			obj_action = next_obj_action
			break
		
	print("OnObjTurn Emit ", obj_action.base_attributes.name_id)
	BehaviorEvents.emit_signal("OnObjTurn", obj_action)
	

# Top action is always 0 AP. This way when we insert a new object it will be the first to act
func NormalizeAP():
	var top_ap = action_list[0].modified_attributes.action_point
	if top_ap == 0:
		return
	for i in range(1,action_list.size()):
		action_list[i].modified_attributes.action_point -= top_ap


func OnObjectLoaded_Callback(obj):
	var attrib = obj.base_attributes
	if attrib.has("action_point"):
		var start_point = attrib.action_point
		obj.modified_attributes["action_point"] = start_point
		Insert(obj, start_point)
		
	
func Insert(obj, action_point):
	for i in range(action_list.size()):
		if action_list[i].modified_attributes.action_point >= action_point:
			action_list.insert(i, obj)
			return
			
	action_list.push_back(obj)
	
	
#func _process(delta):
#	print(action_list)
	
