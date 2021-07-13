extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnConsumeItem", self, "OnConsumeItem_Callback")
	BehaviorEvents.connect("OnSystemDisabled", self, "OnSystemDisabled_Callback")
	BehaviorEvents.connect("OnSystemEnabled", self, "OnSystemEnabled_Callback")
	

func OnSystemEnabled_Callback(obj, system):
	if not "shield" in system:
		return
	
	obj.set_attrib("shield.current_hp", obj.get_attrib("shield.disabled_hp", 0.0))

func OnSystemDisabled_Callback(obj, system):
	if not "shield" in system:
		return
	
	obj.set_attrib("shield.disabled_hp", obj.get_attrib("shield.current_hp", 0.0))
	obj.set_attrib("shield.current_hp", 0.0)
	
func OnObjectLoaded_Callback(obj):
	var cur_shield = obj.get_attrib("shield.current_hp")
	if cur_shield == null:
		var max_shield = obj.get_max_shield()
		if max_shield != 0:
			obj.set_attrib("shield.current_hp", max_shield)
	
func OnObjTurn_Callback(obj):
	var shields = obj.get_attrib("mounts.shield")
	var shields_data = Globals.LevelLoaderRef.LoadJSONArray(shields)
	if obj.get_attrib("offline_systems.shield", 0.0) > 0.0:
		obj.set_attrib("shield.last_turn_update", Globals.total_turn)
		return
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
	var attributes = obj.get_attrib("mount_attributes.shield")
	var last_update = obj.get_attrib("shield.last_turn_update", Globals.total_turn)
	var heal = 0
	var energy = 0
	var count = 0
	
	var packaged_shield = []
	for i in range(shields_data.size()):
		var data = shields_data[i]
		var attribute = attributes[i]
		packaged_shield.push_back({"shield":data, "attribute":attribute})
	packaged_shield.sort_custom(obj, "_sort_by_hp_regen")
	
	for data in packaged_shield:
		# 1, 0.5, 0.25, 0.125, etc.
		heal += data.shield.shielding.hp_regen_per_ap / pow(2, count) * Globals.EffectRef.GetMultiplierValue(obj, data.shield.src, data.attribute, "hp_regen_per_ap_multiplier")
		energy += data.shield.shielding.energy_cost_per_hp * Globals.EffectRef.GetMultiplierValue(obj, data.shield.src, data.attribute, "energy_cost_per_hp_multiplier")
		count += 1
	heal *= Globals.total_turn - last_update
	energy *= Globals.total_turn - last_update
	
	var new_hp = min(cur_hp + heal, max_hp)
	obj.set_attrib("shield.current_hp", new_hp)
	BehaviorEvents.emit_signal("OnUseEnergy", obj, energy)
	
func OnMountAdded_Callback(obj, slot, src, modified_attributes):
	if slot != "shield" or src == null or src.empty():
		return
	
	#TODO: be careful here. What if we had more than one shield and it hasn't been updated ?
	#var data = Globals.LevelLoaderRef.LoadJSON(src)
	obj.set_attrib("shield.last_turn_update", Globals.total_turn)
	
func OnMountRemoved_Callback(obj, slot, src, modified_attributes):
	if slot != "shield" or src == null or src.empty():
		return
		
	var max_hp = obj.get_max_shield()
	
	var cur_hp = obj.get_attrib("shield.current_hp")
	
	if cur_hp == null:
		cur_hp = max_hp
		
	cur_hp = min(cur_hp, max_hp)
	obj.set_attrib("shield.current_hp", cur_hp)
	

func OnConsumeItem_Callback(obj, item_data, key, attrib):
	if not "shield_regen" in item_data:
		return

	BehaviorEvents.emit_signal("OnLogLine", "[color=yelllow]Shield Recharged![/color]")
	
	var max_hp = obj.get_max_shield()
	var cur_hp = obj.get_attrib("shield.current_hp")
	BehaviorEvents.emit_signal("OnValidateConsumption", obj, item_data, key, attrib)
	if cur_hp == null:
		obj.set_attrib("shield.current_hp", max_hp)
		return
		
	if cur_hp < max_hp:
		var heal = Globals.get_data(item_data, "shield_regen.point")
		var new_hp = min(cur_hp + heal, max_hp)
		obj.set_attrib("shield.current_hp", new_hp)
	
