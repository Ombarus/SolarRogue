extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnSystemDisabled", self, "OnSystemDisabled_Callback")
	BehaviorEvents.connect("OnSystemEnabled", self, "OnSystemEnabled_Callback")

func OnSystemDisabled_Callback(obj, system):
	if not "utility" in system:
		return
		
	var applied = obj.get_attrib("cargo.applied_bonus")
	if applied == null or applied == false:
		return # no applied bonus, nothing to do
		
	var utils = str2var(var2str(obj.get_attrib("mounts.utility")))
	_reset_cargo(obj, utils)

func OnSystemEnabled_Callback(obj, system):
	if not "utility" in system:
		return
		
	OnObjectLoaded_Callback(obj)

func _sort_by_cargo_rate(a, b):
	var rate_a = a.cargo_optimizer.per_cargo_space
	var rate_b = b.cargo_optimizer.per_cargo_space
	# reversed sort
	if rate_a > rate_b:
		return true
	return false

func OnObjectLoaded_Callback(obj):
	obj.init_cargo()
	obj.init_mounts()
	
	var applied = obj.get_attrib("cargo.applied_bonus")
	if applied != null and applied == true:
		return # we loaded a savegame and bonus is already up-to-date
	
	var utils = obj.get_attrib("mounts.utility")
	var utils_data = Globals.LevelLoaderRef.LoadJSONArray(utils)
	var per_cargo = _get_per_cargo_compounded(utils_data)
	if per_cargo == null:
		return
		
	var cargo_capacity = obj.get_attrib("cargo.capacity")
	
	obj.set_attrib("cargo.capacity", cargo_capacity * per_cargo)
	obj.set_attrib("cargo.applied_bonus", true)
	
func _get_per_cargo_compounded(utils_data):
	var filtered_cargo = []
	for data in utils_data:
		if "cargo_optimizer" in data:
			filtered_cargo.push_back(data)
	
	if filtered_cargo.size() <= 0:
		return null
	
	filtered_cargo.sort_custom(self, "_sort_by_cargo_rate")
	var per_cargo = 0
	var count = 0
	for data in filtered_cargo:
		per_cargo += (data.cargo_optimizer.per_cargo_space) / pow(2, count) # 1, 0.5, 0.25, 0.125, etc.
		count += 1
	
	return per_cargo
	
	
func _reset_cargo(obj, utils):
	var utils_data = Globals.LevelLoaderRef.LoadJSONArray(utils)
	var per_cargo = _get_per_cargo_compounded(utils_data)
	if per_cargo == null:
		return
	var cargo_capacity = obj.get_attrib("cargo.capacity")
	
	obj.set_attrib("cargo.capacity", cargo_capacity / per_cargo)
	obj.set_attrib("cargo.applied_bonus", false)

func OnMountAdded_Callback(obj, slot, src, modified_attributes):
	if slot != "utility" or src == null or src.empty():
		return
		
	var data = Globals.LevelLoaderRef.LoadJSON(src)
	if "cargo_optimizer" in data:
		var utils = str2var(var2str(obj.get_attrib("mounts.utility"))) # work on a duplicate
		utils.erase(src)
		_reset_cargo(obj, utils)
		# have to recompute everything because of stacking
		OnObjectLoaded_Callback(obj)
	
	
func OnMountRemoved_Callback(obj, slot, src, modified_attributes):
	if slot != "utility" or src == null or src.empty():
		return
		
	var data = Globals.LevelLoaderRef.LoadJSON(src)
	if "cargo_optimizer" in data:
		var utils = str2var(var2str(obj.get_attrib("mounts.utility")))
		utils.push_back(src)
		_reset_cargo(obj, utils)
		# have to recompute everything because of stacking
		OnObjectLoaded_Callback(obj)
