extends Node
class_name APBehavior

export(int) var day_length = 100
var log_window_ref
var action_list = []
var star_date_turn = 0
var star_date_minor = 0
var star_date_major = 0
var _disable = false
var _waiting_on_anim = false
var _need_sort = true

func _ready():
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnUseAP", self, "OnUseAP_Callback")
	BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	
	BehaviorEvents.connect("OnBeginParallelAction", self, "OnBeginParallelAction_Callback")
	BehaviorEvents.connect("OnEndParallelAction", self, "OnEndParallelAction_Callback")
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	
	BehaviorEvents.connect("OnLocaleChanged", self, "OnLocaleChanged_Callback")
	BehaviorEvents.connect("OnHUDCreated", self, "OnHUDCreated_Callback")
	
func OnHUDCreated_Callback():
	log_window_ref = get_node("../../Camera-GUI/SafeArea/HUD_root/HUD/Log/LogWindow")
	
func OnLocaleChanged_Callback():
	UpdateLogTitle()
	
func OnLevelLoaded_Callback():
	if Globals.total_turn > 0:
		star_date_major = floor(Globals.total_turn / 100000)
		star_date_minor = floor(Globals.total_turn / 100)
		star_date_turn = int(Globals.total_turn) % 100
	UpdateLogTitle()
	
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
	_need_sort = true; # a trick to force the AP Behavior to recheck actions after animations have played
	_waiting_on_anim = false
	
func OnTransferPlayer_Callback(old_player, new_player):
	StartAP(new_player, old_player.get_attrib("action_point"))
	StopAP(old_player)
	
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
	
	var base_ap_energy_cost = obj.get_attrib("converter.base_ap_energy_cost")
	var effect_multiplier = Globals.EffectRef.GetMultiplierValue(obj, "", null, "base_ap_cost_multiplier")
	var extra_cost = obj.get_attrib("converter.extra_ap_energy_cost", 0)
	if base_ap_energy_cost != null and base_ap_energy_cost > 0:
		base_ap_energy_cost *= effect_multiplier
		base_ap_energy_cost += extra_cost
		BehaviorEvents.emit_signal("OnUseEnergy", obj, base_ap_energy_cost*amount)
	obj.modified_attributes.action_point += amount
	
	action_list.erase(obj)
	Insert(obj, obj.get_attrib("action_point"))
	
	_need_sort = true
	BehaviorEvents.emit_signal("OnAPUsed", obj, amount)
	
	
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
	if star_date_turn >= day_length:
		star_date_turn -= day_length
		star_date_minor += 1
	if star_date_minor >= day_length:
		star_date_minor -= day_length
		star_date_major += 1
	UpdateLogTitle()

func UpdateLogTitle():
	if log_window_ref == null:
		return
	var title = Globals.mytr("Log Stardate %d.%d.%d", [star_date_major, star_date_minor, star_date_turn])
	log_window_ref.set_title(title, false)
	
func StopAP(obj):
	var index = action_list.find(obj)
	if index < 0:
		return
	
	action_list.remove(index)
	# without setting action_point disabled, if we load it will end back in the action list
	obj.set_attrib("action_point", {"disabled":true})
	
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
	
	
func _process(delta):
	if _waiting_on_anim == true or _need_sort == false or action_list.size() <= 0:
		return
		
	var max_obj_per_turn = 15
	var cur_obj_index = 0
	var one_player_update = false
	
	while cur_obj_index < max_obj_per_turn and _waiting_on_anim == false and _need_sort == true and one_player_update == false:
		
		var obj_action = action_list[0]
		var top_ap = obj_action.get_attrib("action_point")
		for i in range(action_list.size()):
			var next_obj_action = action_list[i]
			var next_ap = next_obj_action.get_attrib("action_point")
			if next_ap != top_ap:
				break
			# at equal ap, player always go first
			if next_obj_action.get_attrib("type") == "player":
				one_player_update = true
				obj_action = next_obj_action
				break
			
		NormalizeAP()
		
		_need_sort = false
		validate_emit_OnObjTurn(obj_action)
		cur_obj_index += 1
		
	
