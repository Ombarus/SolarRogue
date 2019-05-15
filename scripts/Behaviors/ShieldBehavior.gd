extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	
func _sort_by_shield_size(a, b):
	var rate_a = a.shielding.max_hp
	var rate_b = b.shielding.max_hp
	# reversed sort
	if rate_a > rate_b:
		return true
	return false
	
func _sort_by_shield_regen(a, b):
	var rate_a = a.shielding.hp_regen_per_ap
	var rate_b = b.shielding.hp_regen_per_ap
	# reversed sort
	if rate_a > rate_b:
		return true
	return false

	
func OnObjectLoaded_Callback(obj):
	var cur_shield = obj.get_attrib("shield.current_hp")
	if cur_shield == null:
		obj.set_attrib("shield.current_hp", obj.get_max_shield())
	
func OnObjTurn_Callback(obj):
	var shields = obj.get_attrib("mounts.shield")
	var shields_data = Globals.LevelLoaderRef.LoadJSONArray(shields)
	if shields_data.size() <= 0:
		return
	
	var max_hp = obj.get_max_shield()
	var cur_hp = obj.get_attrib("shield.current_hp")
	if cur_hp == null:
		obj.set_attrib("shield.current_hp", max_hp)
		return
		
	if cur_hp < max_hp:
		_process_healing(obj, max_hp, cur_hp, shields_data)
		
	obj.set_attrib("shield.last_turn_update", Globals.total_turn)
		
		
func _process_healing(obj, max_hp, cur_hp, shields_data):
	var last_update = obj.get_attrib("shield.last_turn_update", Globals.total_turn)
	var heal = 0
	var energy = 0
	var count = 0
	for data in shields_data:
		heal += data.shielding.hp_regen_per_ap / pow(2, count) # 1, 0.5, 0.25, 0.125, etc.
		energy += data.shielding.energy_cost_per_hp
		count += 1
	heal *= Globals.total_turn - last_update
	energy *= Globals.total_turn - last_update
	
	var new_hp = min(cur_hp + heal, max_hp)
	obj.set_attrib("shield.current_hp", new_hp)
	BehaviorEvents.emit_signal("OnUseEnergy", obj, energy)
	
func OnMountAdded_Callback(obj, slot, src):
	if slot != "shield" or src == null or src.empty():
		return
	
	#TODO: be careful here. What if we had more than one shield and it hasn't been updated ?
	var data = Globals.LevelLoaderRef.LoadJSON(src)
	obj.set_attrib("shield.last_turn_update", Globals.total_turn)
	
func OnMountRemoved_Callback(obj, slot, src):
	if slot != "shield" or src == null or src.empty():
		return
		
	var max_hp = obj.get_max_shield()
	
	var cur_hp = obj.get_attrib("shield.current_hp")
	
	if cur_hp == null:
		cur_hp = max_hp
		
	cur_hp = min(cur_hp, max_hp)
	obj.set_attrib("shield.current_hp", cur_hp)
