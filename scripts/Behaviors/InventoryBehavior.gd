extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnPickup", self, "OnPickup_Callback")
	BehaviorEvents.connect("OnDropCargo", self, "OnDropCargo_Callback")
	BehaviorEvents.connect("OnDropMount", self, "OnDropMount_Callback")
	BehaviorEvents.connect("OnRemoveMount", self, "OnRemoveMount_Callback")
	BehaviorEvents.connect("OnAddItem", self, "OnAddItem_Callback")
	BehaviorEvents.connect("OnRemoveItem", self, "OnRemoveItem_Callback")
	BehaviorEvents.connect("OnUseEnergy", self, "OnUseEnergy_Callback")
	BehaviorEvents.connect("OnEquipMount", self, "OnEquipMount_Callback")
	BehaviorEvents.connect("OnClearMounts", self, "OnClearMounts_Callback")
	BehaviorEvents.connect("OnClearCargo", self, "OnClearCargo_Callback")
	BehaviorEvents.connect("OnReplaceCargo", self, "OnReplaceCargo_Callback")
	BehaviorEvents.connect("OnUpdateCargoVolume", self, "OnUpdateCargoVolume_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	

func sort_by_chance(a, b):
	if a.chance > b.chance:
		return true
	return false
	
func OnObjectLoaded_Callback(obj):
	var choice_table : Array = obj.get_attrib("cargo.random_content", [])
	if choice_table.size() <= 0:
		return
		
	var inv_size_range = obj.get_attrib("cargo.random_content_size")

	choice_table.sort_custom(self, "sort_by_chance")
	
	var actual_inv_size = MersenneTwister.rand(inv_size_range[1]-inv_size_range[0]) + inv_size_range[0]
	var max_pond_content = 0
	for item in choice_table:
		max_pond_content += item.chance
	
	var actual_content : Array = obj.get_attrib("cargo.content", [])
	for i in range(actual_inv_size):
		var target = MersenneTwister.rand(max_pond_content)
		var selected_item = null
		var sum = 0
		for item in choice_table:
			if "global_max" in item and Globals.LevelLoaderRef.GetGlobalSpawn(item.src) >= item.global_max:
				continue
			if "max" in item and item["max"] <= 0:
				continue
			if sum + item.chance > target:
				selected_item = item.src
				if "max" in item:
					item["max"] -= 1
				break
			sum += item.chance
		# Could be null in cases where for example we've reached max on all spawnable objects in the cargo list.
		# I think it's fine to fail gracefully instead of trying desperatly to add one more item
		if selected_item != null:
			var added := false
			for item in actual_content:
				if item.src == selected_item:
					var data = Globals.LevelLoaderRef.LoadJSON(selected_item)
					var stackable : bool = Globals.get_data(data, "equipment.stackable", false)
					if stackable == true:
						added = true
						item.count += 1
			if added == false:
				var modified_attributes = {}
				var item_data = Globals.LevelLoaderRef.LoadJSON(selected_item)
				var variations = Globals.get_data(item_data, "variations", [])
				if variations.size() > 0:
					modified_attributes = {"selected_variation":MersenneTwister.rand_weight(variations, "src", "chance")}
				
				var c = {"src":selected_item, "count":1}
				if modified_attributes != null and not modified_attributes.empty():
					c["modified_attributes"] = modified_attributes
				actual_content.push_back(c)
		
	obj.set_attrib("cargo.content", actual_content)
	
	
func OnUseEnergy_Callback(obj, amount):
	var destroyed = obj.get_attrib("destroyable.destroyed")
	var is_destroyed : bool = destroyed != null and destroyed == true
	if amount == 0 or obj.get_attrib("converter.stored_energy") == null or is_destroyed:
		return
		
	var cur_energy = obj.get_attrib("converter.stored_energy")
	cur_energy -= amount
	obj.set_attrib("converter.stored_energy", cur_energy)
	if cur_energy <= 0 and obj.get_attrib("type") == "player":
		# prevent calling OnPlayerDeath multiple times
		obj.set_attrib("destroyable.destroyed", true)
		BehaviorEvents.emit_signal("OnPlayerDeath", obj)
	else:
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
		elif ("equipment" in obj.base_attributes or "equipment" in obj.modified_attributes) and obj.get_attrib("cargo.content") != null and is_player:
			BehaviorEvents.emit_signal("OnLogLine", "We should transfer any remaining items from %s before", [Globals.EffectRef.get_object_display_name(obj)])
			
	if filtered_obj.size() <= 0 && is_player:
		var log_choices = {
			"The tractor beam failed to lock on":50,
			"We've picked-up empty space":50,
			"There's Nothing here":50,
			"Failed to lock on any signal":50
		}
		BehaviorEvents.emit_signal("OnLogLine", log_choices)
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
		BehaviorEvents.emit_signal("OnPickObject", picker, obj) # warning, obj will be invalid after this call
		var modified_attrib = obj.modified_attributes
		var volume_mult = Globals.EffectRef.GetMultiplierValue(picker, obj.get_attrib("src"), modified_attrib, "volume_multiplier")
		var item_volume = obj.get_attrib("equipment.volume") * volume_mult
		picker.set_attrib("cargo.volume_used", picker.get_attrib("cargo.volume_used") + item_volume)
		inventory_space -= item_volume
		var variation_src = Globals.clean_path(obj.get_attrib("selected_variation", ""))
		if is_player:
				BehaviorEvents.emit_signal("OnLogLine", "Tractor beam has brought %s abord", [Globals.EffectRef.get_object_display_name(obj)])
		if obj.get_attrib("equipment.stackable"):
			var found = false
			for item in picker.get_attrib("cargo.content"):
				var item_variation = Globals.clean_path(Globals.get_data(item, "modified_attributes.selected_variation", ""))
				if Globals.clean_path(item.src) == Globals.clean_path(obj.get_attrib("src")) and variation_src == item_variation:
					found = true
					item.count += 1
			if not found:
				picker.get_attrib("cargo.content").push_back({"src": obj.base_attributes.src, "count":1, "modified_attributes":modified_attrib})
		else:
			picker.get_attrib("cargo.content").push_back({"src": obj.base_attributes.src, "count":1, "modified_attributes":modified_attrib})
		total_pickup_ap += pickup_speed
		BehaviorEvents.emit_signal("OnRequestObjectUnload", obj)
		obj = null
	if total_pickup_ap > 0:
		BehaviorEvents.emit_signal("OnObjectsPicked", picker)
		BehaviorEvents.emit_signal("OnUseAP", picker, total_pickup_ap)
	filtered_obj.clear() # the objects have been destroyed, just want to make sure I don't forget about it
	

func OnDropCargo_Callback(dropper, item_id, modified_attributes, count):
	if not dropper.modified_attributes.has("cargo"):
		dropper.init_cargo()
	var cargo = dropper.get_attrib("cargo.content")
	var index_to_delete = []
	var i = 0
	var drop_speed = dropper.get_attrib("cargo.drop_ap", 0)
	var is_player = dropper.get_attrib("type") == "player"
	var modif_data = null
	if modified_attributes != null and not modified_attributes.empty():
		modif_data = modified_attributes
	if is_player:
		# hack to make sure when player does goto he doesn't get interrupted by his own drops
		if modif_data == null:
			modif_data = {}
		modif_data["memory"] ={"was_seen_by":true}
	var total_ap_cost = 0
	for item in cargo:
		if Globals.clean_path(item_id) == Globals.clean_path(item.src) and \
			Globals.clean_path(Globals.get_data(item, "modified_attributes.selected_variation", "")) == Globals.clean_path(Globals.get_data(modified_attributes, "selected_variation", "")):
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			var amount_dropped = 0
			if item.count > count:
				item.count -= count
				amount_dropped = count
			else:
				amount_dropped = item.count
				index_to_delete.push_back(i)
			
			var modified_attrib = item.get("modified_attributes", {})
			var volume_mult = Globals.EffectRef.GetMultiplierValue(dropper, item.src, modified_attrib, "volume_multiplier")
			var item_volume = data.equipment.volume * volume_mult
			dropper.set_attrib("cargo.volume_used", dropper.get_attrib("cargo.volume_used") - (item_volume*amount_dropped))
			total_ap_cost += drop_speed * amount_dropped
			for t in range(amount_dropped):
				BehaviorEvents.emit_signal("OnItemDropped", dropper, item_id, modified_attributes)
				Globals.LevelLoaderRef.RequestObject(item.src, Globals.LevelLoaderRef.World_to_Tile(dropper.position), modif_data)
			# found item, we can quit the loop
			break
		i += 1
	if total_ap_cost > 0:
		BehaviorEvents.emit_signal("OnUseAP", dropper, total_ap_cost)
					
	for index in index_to_delete:
		cargo.remove(index)
		
	# This has to be done manually as get_attrib will always return null if disabled is true (which is the point)
	if "equipment" in dropper.modified_attributes or "equipment" in dropper.base_attributes:
		var should_enable : bool = cargo.size() > 0
		dropper.set_attrib("equipment.disabled", should_enable)
	
func OnDropMount_Callback(dropper, slot_name, index):
	var items = dropper.get_attrib("mounts." + slot_name)
	var item_attributes = dropper.get_attrib("mount_attributes." + slot_name)
	var item_id = items[index]
	var item_attribute = item_attributes[index]
	
	# I want to keep the modified_attributes param null if there's nothing important
	# because I skip some steps in RequestObject if there's a non-null param
	var modif_data = null
	if item_attribute != null and not item_attribute.empty():
		modif_data = item_attribute
		
	var data = Globals.LevelLoaderRef.LoadJSON(item_id)
	var drop_ap = 0
	if "equipment" in data and "unequip_ap" in data.equipment and data.equipment.unequip_ap > 0:
		BehaviorEvents.emit_signal("OnUseAP", dropper, data.equipment.unequip_ap)
	Globals.LevelLoaderRef.RequestObject(item_id, Globals.LevelLoaderRef.World_to_Tile(dropper.position), modif_data)
	items[index] = ""
	item_attributes[index] = ""
	dropper.set_attrib("mounts." + slot_name, items)
	dropper.set_attrib("mount_attributes." + slot_name, item_attributes)
	BehaviorEvents.emit_signal("OnMountRemoved", dropper, slot_name, item_id, item_attribute)
	
func OnRemoveMount_Callback(dropper, slot_name, index):
	var items = dropper.get_attrib("mounts." + slot_name)
	var item_id = items[index]
	var data = Globals.LevelLoaderRef.LoadJSON(item_id)
	var drop_ap = 0
	if "equipment" in data and "unequip_ap" in data.equipment and data.equipment.unequip_ap > 0:
		BehaviorEvents.emit_signal("OnUseAP", dropper, data.equipment.unequip_ap)
	#Globals.LevelLoaderRef.RequestObject(item_id, Globals.LevelLoaderRef.World_to_Tile(dropper.position))
	var mount_attrib = dropper.get_attrib("mount_attributes." + slot_name)
	mount_attrib = mount_attrib[index]
	BehaviorEvents.emit_signal("OnAddItem", dropper, items[index], mount_attrib)
	items[index] = ""
	dropper.set_attrib("mounts." + slot_name, items)
	BehaviorEvents.emit_signal("OnMountRemoved", dropper, slot_name, item_id, mount_attrib)
	
func OnEquipMount_Callback(equipper, slot_name, index, item_id, modified_attributes):
	# Check if slot already has something equipped
	# Add old item to cargo
	# Remove current equipment (takes AP)
	# Remove item from cargo
	# Add item_id to mount point
	if modified_attributes == null:
		modified_attributes = {}
	var new_data = null
	if item_id != null and item_id != "":
		new_data = Globals.LevelLoaderRef.LoadJSON(item_id)
	var attrib_getter = "mounts." + slot_name
	var var_getter = "mount_attributes." + slot_name
	var items = equipper.get_attrib(attrib_getter)
	var variations = equipper.get_attrib(var_getter)
	if items != null and items[index] != "":
		BehaviorEvents.emit_signal("OnAddItem", equipper, items[index], variations[index])
		var old_id = items[index]
		var old_data : Dictionary = Globals.LevelLoaderRef.LoadJSON(items[index])
		var unequip_ap : int = Globals.get_data(old_data, "equipment.equip_ap", 0)
		if unequip_ap > 0:
			BehaviorEvents.emit_signal("OnUseAP", equipper, unequip_ap)
		if equipper.get_attrib("type") == "player" and old_data != null and new_data != null:
			#BehaviorEvents.emit_signal("OnLogLine", "Replaced %s by %s", [Globals.mytr(old_data.name_id), Globals.mytr(new_data.name_id)])
			BehaviorEvents.emit_signal("OnLogLine", "Replaced %s by %s", [Globals.EffectRef.get_display_name(old_data, variations[index]), Globals.EffectRef.get_display_name(new_data, modified_attributes)])
		items[index] = ""
		BehaviorEvents.emit_signal("OnMountRemoved", equipper, slot_name, old_id, variations[index])
	elif equipper.get_attrib("type") == "player" and new_data != null:
		BehaviorEvents.emit_signal("OnLogLine", "Installed %s", [Globals.EffectRef.get_display_name(new_data, modified_attributes)])
		
	BehaviorEvents.emit_signal("OnRemoveItem", equipper, item_id, modified_attributes)
	items[index] = item_id
	variations[index] = modified_attributes
	equipper.set_attrib(attrib_getter, items)
	equipper.set_attrib(var_getter, variations)
	var equip_ap : int = Globals.get_data(new_data, "equipment.equip_ap", 0)
	if equip_ap > 0:
		BehaviorEvents.emit_signal("OnUseAP", equipper, equip_ap)
	BehaviorEvents.emit_signal("OnMountAdded", equipper, slot_name, item_id, modified_attributes)

#TODO: Fix logic flaws (make sure we're not changing cargo in base_attributes), (check we won't exceed volume before adding)
func OnAddItem_Callback(picker, item_id, modified_attributes):
	if not picker.modified_attributes.has("cargo"):
		picker.init_cargo()
	if modified_attributes == null:
		modified_attributes = {}
	var cargo = picker.get_attrib("cargo.content")
	var data = Globals.LevelLoaderRef.LoadJSON(item_id)
	
	var volume_mult = Globals.EffectRef.GetMultiplierValue(picker, item_id, modified_attributes, "volume_multiplier")
	
	var volume = data.equipment.volume * volume_mult
	var found = false
	if "stackable" in data.equipment and data.equipment.stackable == true:
		for item in cargo:
			if Globals.clean_path(item_id) == Globals.clean_path(item.src):
				found = true
				item.count += 1
	if found == false:
		var d : Dictionary = {"src": item_id, "count":1}
		if modified_attributes != null and not modified_attributes.empty():
			d["modified_attributes"] = modified_attributes
		cargo.push_back(d)
		
	picker.set_attrib("cargo.volume_used", picker.get_attrib("cargo.volume_used") + volume)
	
	# This has to be done manually as get_attrib will always return null if disabled is true (which is the point)
	if "equipment" in picker.modified_attributes or "equipment" in picker.base_attributes:
		var should_enable : bool = cargo.size() > 0
		picker.set_attrib("equipment.disabled", should_enable)
	
func OnRemoveItem_Callback(holder, item_id, modified_attributes, num_remove=1): #-1 to remove everything
	if not holder.modified_attributes.has("cargo"):
		holder.init_cargo()
	if modified_attributes == null:
		modified_attributes = {}
	var cargo = holder.get_attrib("cargo.content")
	var index_to_delete = []
	var i = 0
	var item_variation = Globals.clean_path(modified_attributes.get("selected_variation", ""))
	for item in cargo:
		var cargo_variation = Globals.clean_path(Globals.get_data(item, "modified_attributes.selected_variation", ""))
		if Globals.clean_path(item_id) == Globals.clean_path(item.src) and cargo_variation == item_variation:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			var volume_mult = Globals.EffectRef.GetMultiplierValue(holder, item_id, modified_attributes, "volume_multiplier")
			if num_remove < 0:
				num_remove = item.count
			holder.set_attrib("cargo.volume_used", holder.get_attrib("cargo.volume_used") - (data.equipment.volume * volume_mult * num_remove))
			if item.count > num_remove:
				item.count -= num_remove
			else:
				index_to_delete.push_back(i)
			break
		i += 1
					
	for index in index_to_delete:
		cargo.remove(index)
		
	# This has to be done manually as get_attrib will always return null if disabled is true (which is the point)
	if "equipment" in holder.modified_attributes or "equipment" in holder.base_attributes:
		var should_enable : bool = cargo.size() > 0
		holder.set_attrib("equipment.disabled", should_enable)
		
		

#TODO: Implement this and replace bad code in player's OnTransferItemCompleted_Callback()	
func OnReplaceCargo_Callback(obj, new_cargo):
	pass
		
func OnClearMounts_Callback(holder):
	if not holder.modified_attributes.has("mounts"):
		holder.init_mounts()
	var mounts = holder.get_attrib("mounts")
	for key in mounts:
		var items = mounts[key]
		var attributes = holder.get_attrib("mount_attributes." + key)
		for i in range(items.size()):
			var item_id = items[i]
			items[i] = ""
			BehaviorEvents.emit_signal("OnMountRemoved", holder, key, item_id, attributes[i])
	
func OnClearCargo_Callback(holder):
	if not holder.modified_attributes.has("cargo"):
		holder.init_cargo()
	# Need to be a copy since we'll be removing item as we iterate on it
	var cargo = holder.get_attrib("cargo.content").duplicate()
	for item in cargo:
		OnRemoveItem_Callback(holder, item.src, item.get("modified_attributes", {}), -1)
		
#objects = [{"src":"bleh.json", "count":3}]
func GetTotalVolume(objects, src_entity):
	var total_volume = 0
	for item in objects:
		var data = Globals.LevelLoaderRef.LoadJSON(item.src)
		var volume = Globals.get_data(data, "equipment.volume")
		if volume != null:
			var volume_mult = Globals.EffectRef.GetMultiplierValue(src_entity, item.src, item.get("modified_attributes", {}), "volume_multiplier")
			total_volume += data.equipment.volume * volume_mult * item["count"]
		
	return total_volume
	
	
func OnUpdateCargoVolume_Callback(obj):
	obj.init_cargo()
	var cargo = obj.get_attrib("cargo.content")
	var total_volume = GetTotalVolume(cargo, obj)
	obj.set_attrib("cargo.volume_used", total_volume)
