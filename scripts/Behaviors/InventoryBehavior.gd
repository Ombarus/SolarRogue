extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnPickup", self, "OnPickup_Callback")
	BehaviorEvents.connect("OnDropCargo", self, "OnDropCargo_Callback")
	BehaviorEvents.connect("OnDropMount", self, "OnDropMount_Callback")
	BehaviorEvents.connect("OnAddItem", self, "OnAddItem_Callback")
	
	
func OnPickup_Callback(picker, picked):
	var picked_obj = []
	var is_player = picker.get_attrib("type") == "player"
	if typeof(picked) == TYPE_VECTOR2:
		picked_obj = Globals.LevelLoaderRef.levelTiles[picked.x][picked.y]
	elif picked is Node:
		picked_obj = [picked]
		
	var filtered_obj = []
	for obj in picked_obj:
		if obj.get_attrib("equipment") != null:
			filtered_obj.push_back(obj)
			
	if filtered_obj.size() <= 0 && is_player:
		BehaviorEvents.emit_signal("OnLogLine", "The tractor beam failed to lock on")
		return
		
	if not picker.modified_attributes.has("cargo"):
		picker.init_cargo()
	var inventory_space = picker.get_attrib("cargo.capacity") - picker.get_attrib("cargo.volume_used")
	for obj in filtered_obj:
		if obj.get_attrib("equipment.volume") > inventory_space:
			if is_player:
				BehaviorEvents.emit_signal("OnLogLine", "Cannot pick up " + obj.get_attrib("name_id") + " Cargo holds are full")
			continue
		picker.set_attrib("cargo.volume_used", picker.get_attrib("cargo.volume_used") + obj.get_attrib("equipment.volume"))
		inventory_space -= obj.get_attrib("equipment.volume")
		if is_player:
				BehaviorEvents.emit_signal("OnLogLine", "Tractor beam has brought " + obj.get_attrib("name_id") + " abord")
		if obj.get_attrib("equipment.stackable"):
			var found = false
			for item in picker.get_attrib("cargo.content"):
				if item.src in obj.get_attrib("src"):
					found = true
					item.count += 1
			if not found:
				picker.get_attrib("cargo.content").push_back({"src": obj.base_attributes.src, "count":1})
		else:
			picker.get_attrib("cargo.content").push_back({"src": obj.base_attributes.src, "count":1})
		BehaviorEvents.emit_signal("OnRequestObjectUnload", obj)
		obj = null
	filtered_obj.clear() # the objects have been destroyed, just want to make sure I don't forget about it
	

func OnDropCargo_Callback(dropper, item_id):
	var cargo = dropper.get_attrib("cargo.content")
	var index_to_delete = []
	for item_data in cargo:
		if item_data.src == item_id:
			if item_data.count > 1:
				item_data.count -= 1
			else:
				index_to_delete.push_back(i)
			Globals.LevelLoaderRef.RequestObject(item_data.src, Globals.LevelLoaderRef.World_to_Tile(dropper.position))
					
	for index in index_to_delete:
		cargo.remove(index)
	
func OnDropMount_Callback(dropper, item_id):
	var equips = dropper.get_attrib("mounts")
	for equip in equips:
		if item_id == equip:
			Globals.LevelLoaderRef.RequestObject(dropper.get_attrib("mounts." + equip), Globals.LevelLoaderRef.World_to_Tile(dropper.position))
			dropper.set_attrib("mounts." + equip, "")

func OnAddItem_Callback():
	pass
