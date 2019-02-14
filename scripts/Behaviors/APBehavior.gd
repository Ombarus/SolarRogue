extends Node

export(NodePath) var LogWindow
export(int) var day_length = 100
var log_window_ref
var action_list = []
var star_date_turn = 0
var star_date_minor = 0
var star_date_major = 0
var _disable = false
var _waiting_on_anim = false

func _ready():
	log_window_ref = get_node(LogWindow)
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnUseAP", self, "OnUseAP_Callback")
	BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	
	BehaviorEvents.connect("OnBeginParallelAction", self, "OnBeginParallelAction_Callback")
	BehaviorEvents.connect("OnEndParallelAction", self, "OnEndParallelAction_Callback")

	
func OnBeginParallelAction_Callback(obj):
	obj.set_attrib("ap.is_parallel", true)
	obj.set_attrib("ap.accumulator", [])
	
func OnEndParallelAction_Callback(obj):
	obj.set_attrib("ap.is_parallel", false)
	var ap_list = obj.get_attrib("ap.accumulator")
	if ap_list == null or ap_list.size() <= 0:
		return
		
	var max_ap = 0
	for ap in ap_list:
		if max_ap < ap:
			max_ap = ap
			
	if max_ap > 0:
		OnUseAP_Callback(obj, max_ap)
	
	
func OnWaitForAnimation_Callback():
	_waiting_on_anim = true
	
func OnAnimationDone_Callback():
	_waiting_on_anim = false
	
func OnTransferPlayer_Callback(old_player, new_player):
	StopAP(old_player)
	StartAP(new_player, old_player.get_attrib("action_point"))
	
func OnRequestObjectUnload_Callback(obj):
	if obj.get_attrib("type") == "player":
		_disable = true
	action_list.erase(obj)

func OnUseAP_Callback(obj, amount):		
	obj.set_attrib("ap.ai_acted", true)
	var index = action_list.find(obj)
	if index < 0:
		return
		
	if obj.get_attrib("ap.is_parallel") == true:
		obj.get_attrib("ap.accumulator").push_back(amount)
		return
	
	action_list.remove(index)	
	var base_ap_energy_cost = obj.get_attrib("converter.base_ap_energy_cost")
	if base_ap_energy_cost != null and base_ap_energy_cost > 0:
		BehaviorEvents.emit_signal("OnUseEnergy", obj, base_ap_energy_cost)
	obj.modified_attributes.action_point += amount
	Insert(obj, obj.get_attrib("action_point"))
	NormalizeAP()
	
	var obj_action = action_list[0]
	var top_ap = obj_action.get_attrib("action_point")
	for i in range(action_list.size()):
		var next_obj_action = action_list[i]
		var next_ap = next_obj_action.get_attrib("action_point")
		if next_ap != top_ap:
			break
		# at equal ap, player always go first
		if next_obj_action.get_attrib("type") == "player":
			obj_action = next_obj_action
			break
		
	# OnobjTurn triggers OnUseAp so this is circular.
	# The only reason it won't crash right away is that the player waits for input
	# using call_deferred should allow us to "queue" the OnObjTurn and do them in sequence (or even in parallel)
	if _waiting_on_anim:
		yield(BehaviorEvents, "OnAnimationDone")
		
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
	
func StopAP(obj):
	var index = action_list.find(obj)
	if index < 0:
		return
	
	action_list.remove(index)
	
func StartAP(obj, start_point=0):
	var index = action_list.find(obj)
	if index >= 0:
		return
	
	obj.set_attrib("action_point", start_point)
	Insert(obj, start_point)

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
	
