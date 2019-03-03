extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnPickup", self, "OnPickup_Callback")
	BehaviorEvents.connect("OnDropCargo", self, "OnDropCargo_Callback")
	BehaviorEvents.connect("OnDropMount", self, "OnDropMount_Callback")
	BehaviorEvents.connect("OnAddItem", self, "OnAddItem_Callback")
	BehaviorEvents.connect("OnRemoveItem", self, "OnRemoveItem_Callback")
	BehaviorEvents.connect("OnUseEnergy", self, "OnUseEnergy_Callback")
	BehaviorEvents.connect("OnEquipMount", self, "OnEquipMount_Callback")
	BehaviorEvents.connect("OnClearMounts", self, "OnClearMounts_Callback")
	BehaviorEvents.connect("OnClearCargo", self, "OnClearCargo_Callback")
	BehaviorEvents.connect("OnReplaceCargo", self, "OnReplaceCargo_Callback")
	BehaviorEvents.connect("OnReplaceMounts", self, "OnReplaceMounts_Callback")
	BehaviorEvents.connect("OnUpdateCargoVolume", self, "OnUpdateCargoVolume_Callback")
	
func OnUseEnergy_Callback(obj, amount):
	if amount == 0 or obj.get_attrib("converter.stored_energy") == null:
		return
	var cur_energy = obj.get_attrib("converter.stored_energy")
	cur_energy -= amount
	if cur_energy <= 0 and obj.get_attrib("type") == "player" :
		BehaviorEvents.emit_signal("OnPlayerDeath")
	else:
		obj.set_attrib("converter.stored_energy", cur_energy)
		BehaviorEvents.emit_signal("OnEnergyChanged", obj)
	
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
	var pickup_speed = picker.get_attrib("cargo.pickup_ap")
	if pickup_speed == null:
		pickup_speed = 0
	var total_pickup_ap = 0
	for obj in filtered_obj:
		# Allow pickup when over cargo but prevent the player from moving.
		# I think it's better for usability to let the player take what he wants and then
		# decide what to drop instead of having to choose beforehand because we stop him from being
		# over-cargo
		#if obj.get_attrib("equipment.volume") > inventory_space:
		#	if is_player:
		#		BehaviorEvents.emit_signal("OnLogLine", "Cannot pick up " + obj.get_attrib("name_id") + " Cargo holds are full")
		#	continue
		picker.set_attrib("cargo.volume_used", picker.get_attrib("cargo.volume_used") + obj.get_attrib("equipment.volume"))
		inventory_space -= obj.get_attrib("equipment.volume")
		if is_player:
				BehaviorEvents.emit_signal("OnLogLine", "Tractor beam has brought " + obj.get_attrib("name_id") + " abord")
		if obj.get_attrib("equipment.stackable"):
			var found = false
			for item in picker.get_attrib("cargo.content"):
				if Globals.clean_path(item.src) == Globals.clean_path(obj.get_attrib("src")):
					found = true
					item.count += 1
			if not found:
				picker.get_attrib("cargo.content").push_back({"src": obj.base_attributes.src, "count":1})
		else:
			picker.get_attrib("cargo.content").push_back({"src": obj.base_attributes.src, "count":1})
		total_pickup_ap += pickup_speed
		BehaviorEvents.emit_signal("OnRequestObjectUnload", obj)
		obj = null
	if total_pickup_ap > 0:
		BehaviorEvents.emit_signal("OnUseAP", picker, total_pickup_ap)
	filtered_obj.clear() # the objects have been destroyed, just want to make sure I don't forget about it
	

func OnDropCargo_Callback(dropper, item_id):
	if not dropper.modified_attributes.has("cargo"):
		dropper.init_cargo()
	var cargo = dropper.get_attrib("cargo.content")
	var index_to_delete = []
	var i = 0
	var drop_speed = dropper.get_attrib("cargo.drop_ap")
	if drop_speed == null:
		drop_speed = 0
	var total_ap_cost = 0
	for item in cargo:
		if Globals.clean_path(item_id) == Globals.clean_path(item.src):
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			dropper.set_attrib("cargo.volume_used", dropper.get_attrib("cargo.volume_used") - data.equipment.volume)
			if item.count > 1:
				item.count -= 1
			else:
				index_to_delete.push_back(i)
			total_ap_cost += drop_speed
			Globals.LevelLoaderRef.RequestObject(item.src, Globals.LevelLoaderRef.World_to_Tile(dropper.position))
		i += 1
	if total_ap_cost > 0:
		BehaviorEvents.emit_signal("OnUseAP", dropper, total_ap_cost)
					
	for index in index_to_delete:
		cargo.remove(index)
	
func OnDropMount_Callback(dropper, slot_name, index):
	var items = dropper.get_attrib("mounts." + slot_name)
	var item_id = items[index]
	var data = Globals.LevelLoaderRef.LoadJSON(item_id)
	var drop_ap = 0
	if "equipment" in data and "unequip_ap" in data.equipment and data.equipment.unequip_ap > 0:
		BehaviorEvents.emit_signal("OnUseAP", dropper, data.equipment.unequip_ap)
	Globals.LevelLoaderRef.RequestObject(item_id, Globals.LevelLoaderRef.World_to_Tile(dropper.position))
	items[index] = ""
	dropper.set_attrib("mounts." + slot_name, items)
	BehaviorEvents.emit_signal("OnMountRemoved", dropper, slot_name, item_id)
	
func OnEquipMount_Callback(equipper, slot_name, index, item_id):
	# Check if slot already has something equipped
	# Remove current equipment (takes AP)
	# Remove item from cargo
	# Add item_id to mount point
	var attrib_getter = "mounts." + slot_name
	var items = equipper.get_attrib(attrib_getter)
	if items != null and items[index] != "":
		BehaviorEvents.emit_signal("OnDropMount", equipper, slot_name, index)
	BehaviorEvents.emit_signal("OnRemoveItem", equipper, item_id)
	items[index] = item_id
	equipper.set_attrib(attrib_getter, items)
	BehaviorEvents.emit_signal("OnMountAdded", equipper, slot_name, item_id)

#TODO: Fix logic flaws (make sure we're not changing cargo in base_attributes), (check we won't exceed volume before adding)
func OnAddItem_Callback(picker, item_id):
	if not picker.modified_attributes.has("cargo"):
		picker.init_cargo()
	var cargo = picker.get_attrib("cargo.content")
	var data = Globals.LevelLoaderRef.LoadJSON(item_id)
	var volume = data.equipment.volume
	var found = false
	if "stackable" in data.equipment and data.equipment.stackable == true:
		for item in cargo:
			if Globals.clean_path(item_id) == Globals.clean_path(item.src):
				found = true
				item.count += 1
	if found == false:
		cargo.push_back({"src": item_id, "count":1})
		
	picker.set_attrib("cargo.volume_used", picker.get_attrib("cargo.volume_used") + volume)
	
func OnRemoveItem_Callback(holder, item_id, num_remove=1): #-1 to remove everything
	if not holder.modified_attributes.has("cargo"):
		holder.init_cargo()
	var cargo = holder.get_attrib("cargo.content")
	var index_to_delete = []
	var i = 0
	for item in cargo:
		if Globals.clean_path(item_id) == Globals.clean_path(item.src):
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			holder.set_attrib("cargo.volume_used", holder.get_attrib("cargo.volume_used") - data.equipment.volume)
			if num_remove >= 0 and item.count > num_remove:
				item.count -= num_remove
			else:
				index_to_delete.push_back(i)
		i += 1
					
	for index in index_to_delete:
		cargo.remove(index)
		

#TODO: Implement this and replace bad code in player's OnTransferItemCompleted_Callback()	
func OnReplaceCargo_Callback(obj, new_cargo):
	pass

# new_mounts [{mount_key, item.mount_index, item.src_key},...]
func OnReplaceMounts_Callback(obj, new_mounts):
	if not obj.modified_attributes.has("mounts"):
		obj.init_mounts()
	var mounts = obj.get_attrib("mounts")
	for key in mounts:
		var items = mounts[key]
		for i in range(items.size()):
			var item_id = items[i]
			var new_mounts_val = null
			for n in new_mounts:
				if n.mount_key == key and n.mount_index == i and Globals.clean_path(n.src_key) == Globals.clean_path(item_id):
					break
				elif n.mount_key == key and n.mount_index == i:
					items[i] = ""
					BehaviorEvents.emit_signal("OnMountRemoved", obj, key, item_id)
					OnEquipMount_Callback(obj, key, i, n.src_key)
					break
			
		
func OnClearMounts_Callback(holder):
	if not holder.modified_attributes.has("mounts"):
		holder.init_mounts()
	var mounts = holder.get_attrib("mounts")
	for key in mounts:
		var items = mounts[key]
		for i in range(items.size()):
			var item_id = items[i]
			items[i] = ""
			BehaviorEvents.emit_signal("OnMountRemoved", holder, key, item_id)
	
func OnClearCargo_Callback(holder):
	if not holder.modified_attributes.has("cargo"):
		holder.init_cargo()
	# Need to be a copy since we'll be removing item as we iterate on it
	var cargo = holder.get_attrib("cargo.content").duplicate()
	for item in cargo:
		OnRemoveItem_Callback(holder, item.src, -1)
		
#objects = [{"src":"bleh.json", "count":3}]
func GetTotalVolume(objects):
	var total_volume = 0
	for item in objects:
		var data = Globals.LevelLoaderRef.LoadJSON(item.src)
		var volume = Globals.get_data(data, "equipment.volume")
		if volume != null:
			total_volume += data.equipment.volume * item["count"]
		
	return total_volume
	
	
func OnUpdateCargoVolume_Callback(obj):
	obj.init_cargo()
	var cargo = obj.get_attrib("cargo.content")
	var total_volume = GetTotalVolume(cargo)
	obj.set_attrib("cargo.volume_used", total_volume)
