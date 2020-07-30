extends Node

func _ready():
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	
func OnObjTurn_Callback(obj):
	var utils = obj.get_attrib("mounts.utility")
	var utils_data = Globals.LevelLoaderRef.LoadJSONArray(utils)
	var converters_data = Globals.LevelLoaderRef.LoadJSONArray(obj.get_attrib("mounts.converter"))
	if utils_data.size() <= 0 or converters_data.size() <= 0:
		return
	
	var filtered_regen = []
	for data in utils_data:
		if "energy_regen" in data:
			filtered_regen.push_back(data)
			
	if filtered_regen.size() <= 0:
		return
	
	var max_energ = 0
	for data in converters_data:
		max_energ += Globals.get_data(data, "converter.maximum_energy")
	
	var cur_energ = obj.get_attrib("converter.stored_energy")
	
	if cur_energ == null:
		return
		
	if cur_energ < max_energ:
		_process_healing(obj, max_energ, cur_energ, filtered_regen)
	
	#TODO: What happen when ap is disabled for a # of turn ?
	obj.set_attrib("energy_regen.last_turn_update", Globals.total_turn)
		

func _sort_by_regen_rate(a, b):
	var rate_a = a.energy_regen.per_turn
	var rate_b = b.energy_regen.per_turn
	# reversed sort
	if rate_a > rate_b:
		return true
	return false

func _process_healing(obj, max_energ, cur_energ, filtered_regen):
	var last_update = obj.get_attrib("energy_regen.last_turn_update", Globals.total_turn)
	var energy = 0
	if filtered_regen.size() == 1:
		energy = filtered_regen[0].energy_regen.per_turn * (Globals.total_turn - last_update)
	else:
		filtered_regen.sort_custom(self, "_sort_by_regen_rate")
		var count = 0
		for data in filtered_regen:
			energy += data.energy_regen.per_turn / pow(2, count)
			count += 1
		energy *= Globals.total_turn - last_update
	var new_energ = min(cur_energ + energy, max_energ)
	BehaviorEvents.emit_signal("OnUseEnergy", obj, -energy)
	#obj.set_attrib("converter.stored_energy", new_energ)
	
	
func OnMountAdded_Callback(obj, slot, src, modified_attributes):
	if slot != "utility" or src == null or src.empty():
		return
		
	# TODO: if you have multiple regen installed, should probably do a regular update at that point
	# at the same time... chances are that if you're adding a mount it's on your turn so you are already up to date
	# if you had another regen item equiped. This is only in case we skipped the update because you had nothing equiped
	var data = Globals.LevelLoaderRef.LoadJSON(src)
	if "energy_regen" in data:
		obj.set_attrib("energy_regen.last_turn_update", Globals.total_turn)
	
