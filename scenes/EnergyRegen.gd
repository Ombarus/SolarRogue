extends Node

func _ready():
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	
func OnObjTurn_Callback(obj):
	var util_name = obj.get_attrib("mounts.utility")
	var converter_name = obj.get_attrib("mounts.converter")
	if util_name == null or util_name == "" or converter_name == null or converter_name == "":
		return
	
	var util_data = Globals.LevelLoaderRef.LoadJSON(util_name)
	if not "energy_regen" in util_data:
		return
	
	var conv_data = Globals.LevelLoaderRef.LoadJSON(converter_name)
	var max_energ = Globals.get_data(conv_data, "converter.maximum_energy")
	var cur_energ = obj.get_attrib("converter.stored_energy")
	
	if cur_energ == null:
		return
		
	if cur_energ < max_energ:
		_process_healing(obj, max_energ, cur_energ, util_data)
	
	#TODO: What happen when ap is disabled for a # of turn ?
	obj.set_attrib("energy_regen.last_turn_update", Globals.total_turn)
		
		
func _process_healing(obj, max_energ, cur_energ, util_data):
	var last_update = obj.get_attrib("energy_regen.last_turn_update", Globals.total_turn)
	var energy = util_data.energy_regen.per_turn * (Globals.total_turn - last_update)
	
	var new_energ = min(cur_energ + energy, max_energ)
	obj.set_attrib("converter.stored_energy", new_energ)
	
	
func OnMountAdded_Callback(obj, slot, src):
	if slot != "utility" or src == null or src.empty():
		return
		
	var data = Globals.LevelLoaderRef.LoadJSON(src)
	if "energy_regen" in data:
		obj.set_attrib("energy_regen.last_turn_update", Globals.total_turn)
	
