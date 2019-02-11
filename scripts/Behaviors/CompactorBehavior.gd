extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")

func OnObjectLoaded_Callback(obj):
	var utility = obj.get_attrib("mounts.utility")
	if utility != null and not utility.empty():
		var data = Globals.LevelLoaderRef.LoadJSON(utility)
		if "cargo_optimizer" in data:
			obj.init_cargo()
			var per_cargo = data.cargo_optimizer.per_cargo_space
			var cargo_capacity = obj.get_attrib("cargo.capacity")
			
			obj.set_attrib("cargo.capacity", cargo_capacity * per_cargo)

func OnMountAdded_Callback(obj, slot, src):
	if slot != "utility" or src == null or src.empty():
		return
		
	var data = Globals.LevelLoaderRef.LoadJSON(src)
	if "cargo_optimizer" in data:
		obj.init_cargo()
		var per_cargo = data.cargo_optimizer.per_cargo_space
		var cargo_capacity = obj.get_attrib("cargo.capacity")
		
		obj.set_attrib("cargo.capacity", cargo_capacity * per_cargo)
	
	
func OnMountRemoved_Callback(obj, slot, src):
	if slot != "utility" or src == null or src.empty():
		return
		
	var data = Globals.LevelLoaderRef.LoadJSON(src)
	if "cargo_optimizer" in data:
		obj.init_cargo()
		var per_cargo = data.cargo_optimizer.per_cargo_space
		var cargo_capacity = obj.get_attrib("cargo.capacity")
		
		obj.set_attrib("cargo.capacity", cargo_capacity / per_cargo)