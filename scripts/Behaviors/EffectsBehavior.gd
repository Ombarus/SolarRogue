extends Node
class_name EffectBehavior

# Effects are implemeting their own, very confusing, DSL (Domain Specific Language)
# Effects have attributes dictionary. each key-value pair define an effect and the value of that effect
# ex : shield_multiplier define a multiplier to the shield value of a ship
# each effect can have prefixes that tell the game how the multiplier should be applied
# "self_" -> only apply effect to self (ex: weapon damage increase)
# "global_" -> apply to final result (ex: to all weapon damage or to global cargo capacity, etc.)
# "inv_" -> by default, apply only if item is equipped, use inv_ to specify effect applies from inventory too
# "mount_" -> if the item equipment slot matches one of the words in the effect (mount_disable_weapon_chance) will only work on items that can be mounted in weapon mount

# "inv_" is a bit special, it needs to be added separate from other effects
#		so we're going to create a duplicate of the attributes to add to effect list
#		but that also means we need a way to differenciate other than the name of the variation
#		so I'll add another id.


enum COMPOUNDING_TYPE {
	multiply,
	add,
	substract
}

func _ready():
	Globals.EffectRef = self
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnPickObject", self, "OnPickObject_Callback")
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnPickItem", self, "OnAddItem_Callback")
	BehaviorEvents.connect("OnRemoveItem", self, "OnremoveItem_Callback")
	BehaviorEvents.connect("OnItemDropped", self, "OnItemDropped_Callback")
	BehaviorEvents.connect("OnConsumeItem", self, "OnConsumeItem_Callback")
	BehaviorEvents.connect("OnUpdateMountAttribute", self, "OnUpdateMountAttribute_Callback")
	BehaviorEvents.connect("OnSystemDisabled", self, "OnSystemDisabled_Callback")
	BehaviorEvents.connect("OnSystemEnabled", self, "OnSystemEnabled_Callback")

	
func _exit_tree():
	Globals.EffectRef = null
	
func get_object_display_name(obj) -> String:
	var variation_src : String = obj.get_attrib("selected_variation", "")
	var name_id : String = obj.get_attrib("name_id")
	if variation_src.empty():
		return Globals.mytr(name_id)
	
	var variation_data = Globals.LevelLoaderRef.LoadJSON(variation_src)
	if not variation_data["prefix"].empty(): # "normal" effects might have an empty prefix
		return Globals.mytr(variation_data["prefix"], Globals.mytr(name_id))
	else:
		return Globals.mytr(name_id)
	
func get_display_name(data, modified_attributes=null):
	if modified_attributes == null:
		modified_attributes = {}
		
	var display_name = data.name_id
	if not modified_attributes.empty() and modified_attributes.has("selected_variation") and not modified_attributes["selected_variation"].empty():
		var variation_data = Globals.LevelLoaderRef.LoadJSON(modified_attributes["selected_variation"])
		if not variation_data["prefix"].empty(): # "normal" effects might have an empty prefix
			display_name = Globals.mytr(variation_data["prefix"], Globals.mytr(display_name))
			
	return Globals.mytr(display_name)
	
func OnSystemDisabled_Callback(obj, system):
	if not system in ["weapon", "shield", "scanner", "converter", "utility"]:
		return
	
	var mounts : Array = obj.get_attrib("mounts.%s" % system, [])
	var mount_attributes : Array = obj.get_attrib("mount_attributes.%s" % system, [])
	# temporarily remove the effect while the system is disabled
	# ***CAREFUL not to remove it twice while it's disabled***
	for idx in range(mounts.size()):
		if not mounts[idx].empty():
			OnMountRemoved_Callback(obj, system, mounts[idx], mount_attributes[idx], true)
	
	
func OnSystemEnabled_Callback(obj, system):
	if not system in ["weapon", "shield", "scanner", "converter", "utility"]:
		return
		
	var mounts : Array = obj.get_attrib("mounts.%s" % system, [])
	var mount_attributes : Array = obj.get_attrib("mount_attributes.%s" % system, [])
	for idx in range(mounts.size()):
		if not mounts[idx].empty():
			OnMountAdded_Callback(obj, system, mounts[idx], mount_attributes[idx], true)
	
func OnUpdateMountAttribute_Callback(obj, key, idx, new_attrib):
	var mount_attributes = obj.get_attrib("mount_attributes.%s" % key)
	var mounts = obj.get_attrib("mounts.%s" % key)
	#var old_variation = mount_attributes[idx].get("selected_variation", "")
	
	# fake add/remove to reset applied_effects
	if obj.get_attrib("offline_systems.%s" % key, 0.0) <= 0.0:
		OnMountRemoved_Callback(obj, key, mounts[idx], mount_attributes[idx])
		OnMountAdded_Callback(obj, key, mounts[idx], new_attrib)
	
	mount_attributes[idx] = new_attrib
	obj.set_attrib("mount_attributes.%s" % key, mount_attributes)
	
	
func OnItemDropped_Callback(dropper, item_id, modified_attributes):
	if modified_attributes == null or not modified_attributes.has("selected_variation"):
		return
		
	var variation_src : String = Globals.clean_path(modified_attributes.get("selected_variation"))
	var applied_effects : Array = dropper.get_attrib("applied_effects", [])
	for index in range(applied_effects.size()):
		var effect = applied_effects[index]
		if Globals.clean_path(effect.src) == variation_src and effect.get("from_inventory", false) == true:
			applied_effects.remove(index)
			break
			
	dropper.set_attrib("applied_effects", applied_effects)
	
func OnPickObject_Callback(picker, obj):
	var variation_src = obj.get_attrib("selected_variation")
	if variation_src == null:
		return
	
	var variation_data : Dictionary = Globals.LevelLoaderRef.LoadJSON(variation_src)
	var effect_data = variation_data["attributes"]
	
	var inventory_effect = {}
	
	for key in effect_data.keys():
		if "inv_" in key:
			inventory_effect[key] = effect_data[key]
	
	if not inventory_effect.empty():
		inventory_effect["src"] = variation_src
		inventory_effect["from_inventory"] = true
		var applied_effects : Array = picker.get_attrib("applied_effects", [])
		applied_effects.push_back(inventory_effect)
		picker.set_attrib("applied_effects", applied_effects)
	
func OnremoveItem_Callback(holder, item_id, modified_attributes, amount=-1):
	#TODO: not taking amount into account for now. will need to apply/remove multiple effect if
	#		stacakble item can have effects
	if modified_attributes == null or not modified_attributes.has("selected_variation"):
		return
		
	var variation_src : String = Globals.clean_path(modified_attributes.get("selected_variation"))
	var applied_effects : Array = holder.get_attrib("applied_effects", [])
	for index in range(applied_effects.size()):
		var effect = applied_effects[index]
		if Globals.clean_path(effect.src) == variation_src and effect.get("from_inventory", false) == true:
			applied_effects.remove(index)
			break
			
	holder.set_attrib("applied_effects", applied_effects)
	
	
	
func OnAddItem_Callback(picker, item_id, modified_attributes):
	if modified_attributes == null or not modified_attributes.has("selected_variation"):
		return
	
	var variation_src : String = modified_attributes.get("selected_variation")
	var variation_data : Dictionary = Globals.LevelLoaderRef.LoadJSON(variation_src)
	var effect_data = variation_data["attributes"]
	
	var inventory_effect = {}
	
	for key in effect_data.keys():
		if "inv_" in key:
			inventory_effect[key] = effect_data[key]
	
	if not inventory_effect.empty():
		inventory_effect["src"] = variation_src
		inventory_effect["from_inventory"] = true
		var applied_effects : Array = picker.get_attrib("applied_effects", [])
		applied_effects.push_back(inventory_effect)
		picker.set_attrib("applied_effects", applied_effects)
		

func OnMountAdded_Callback(obj, slot, src, modified_attributes, force=false):
	# If a mount is disabled, we'll add the attributes automatically when the mount is re-enabled
	if obj.get_attrib("offline_systems.%s" % slot, 0.0) > 0.0 and force == false:
		return
		
	var src_data = Globals.LevelLoaderRef.LoadJSON(src)
	var obj_attributes = src_data.get("attributes", {})
	if obj_attributes.size() > 0:
		var filtered_effects = {}
		for key in obj_attributes.keys():
			if not "inv_" in key:
				filtered_effects[key] = obj_attributes[key]
		filtered_effects["src"] = src
		var applied_effects : Array = obj.get_attrib("applied_effects", [])
		applied_effects.push_back(filtered_effects)
		obj.set_attrib("applied_effects", applied_effects)
	
	if modified_attributes == null or not modified_attributes.has("selected_variation"):
		return
		
	var variation_src : String = modified_attributes.get("selected_variation")
	var variation_data : Dictionary = Globals.LevelLoaderRef.LoadJSON(variation_src)
	var effect_data = variation_data["attributes"]
	
	# "normal" variation might not have any effects
	if effect_data.empty():
		return
		
	# I'll add the src and I don't want to modify the reference
	var filtered_effects = {}
	for key in effect_data.keys():
		if not "inv_" in key:
			filtered_effects[key] = effect_data[key]
	#effect_data = str2var(var2str(effect_data))
	
	filtered_effects["src"] = variation_src
	var applied_effects : Array = obj.get_attrib("applied_effects", [])
	applied_effects.push_back(filtered_effects)
	obj.set_attrib("applied_effects", applied_effects)
	
	
func OnMountRemoved_Callback(obj, slot, src, modified_attributes, force=false):
	# If a mount is disabled, we've already removed the attributes
	if obj.get_attrib("offline_systems.%s" % slot, 0.0) > 0.0 and force == false:
		return
		
	# Remove effects from object like utility
	var applied_effects : Array = obj.get_attrib("applied_effects", [])
	for index in range(applied_effects.size()):
		var effect = applied_effects[index]
		if Globals.clean_path(effect.src) == Globals.clean_path(src) and effect.get("from_inventory", false) == false:
			applied_effects.remove(index)
			break
	
	if modified_attributes == null or not modified_attributes.has("selected_variation"):
		return
		
	# Remove effects from variations
	var variation_src : String = Globals.clean_path(modified_attributes.get("selected_variation"))
	for index in range(applied_effects.size()):
		var effect = applied_effects[index]
		if Globals.clean_path(effect.src) == variation_src and effect.get("from_inventory", false) == false:
			applied_effects.remove(index)
			break
			
	obj.set_attrib("applied_effects", applied_effects)


func OnObjectLoaded_Callback(obj):
	var selected_variation = obj.get_attrib("selected_variation")
	if selected_variation != null:
		return
		
		
	if obj.get_attrib("converter", null) != null:
		process_recipes_attributes(obj)
		
	var variations = obj.get_attrib("variations", [])
	if variations.size() <= 0:
		return
		
	selected_variation = MersenneTwister.rand_weight(variations, "src", "chance")
	
	obj.set_attrib("selected_variation", selected_variation)
	

func OnConsumeItem_Callback(obj, item_data, key, attrib):
	var update_effect = Globals.get_data(item_data, "update_effect")
	var triggering_data = {"item_data":item_data, "key":key, "attrib":attrib}
	if update_effect == null:
		return
	
	# for now we can only remove effects
	var effect_to_remove = Globals.clean_path(update_effect.get("remove", ""))
	if effect_to_remove.empty():
		return
		
	# find all broken item
	var affected_src := []
	var mounts = obj.get_attrib("mounts")
	for key in mounts:
		var items = mounts[key]
		var attributes = obj.get_attrib("mount_attributes." + key)
		for i in range(items.size()):
			if Globals.clean_path(Globals.get_data(attributes[i], "selected_variation", "")) == effect_to_remove:
				var affected_data = Globals.LevelLoaderRef.LoadJSON(items[i])
				affected_src.push_back({"key":key, "idx":i, "item_id":items[i], "modified_attributes":attributes[i], "item_data":affected_data, "triggering_data":triggering_data})
			
	var cargo = obj.get_attrib("cargo.content")
	for item in cargo:
		if Globals.clean_path(Globals.get_data(item, "modified_attributes.selected_variation", "")) == effect_to_remove:
			var affected_data = Globals.LevelLoaderRef.LoadJSON(item.src)
			affected_src.push_back({"item_id":item.src, "modified_attributes":item.get("modified_attributes", {}), "item_data":affected_data, "triggering_data":triggering_data})
	
	# display choice dialog
	BehaviorEvents.emit_signal("OnPushGUI", "SelectTarget", {"targets":affected_src, "callback_object":self, "callback_method":"SelectedTarget_Callback"})
	

func SelectedTarget_Callback(selected_targets):
	# process choice
	var modified_attributes = selected_targets[0].modified_attributes
	var item_data = selected_targets[0].item_data
	var item_id = selected_targets[0].item_id
	var key = selected_targets[0].get("key", null)
	var mount_idx = selected_targets[0].get("idx", null)
	var player = Globals.get_first_player()
	
	var triggering_data = selected_targets[0].triggering_data
	var default_variation = "data/json/items/effects/normal.json"
	
	if key == null:
		# update inventory
		var new_data = str2var(var2str(modified_attributes))
		var previous_variation = new_data.get("previous_variation", "")
		if not previous_variation.empty():
			default_variation = previous_variation
			new_data.erase("previous_variation")
		Globals.set_data(new_data, "selected_variation", default_variation)
		BehaviorEvents.emit_signal("OnUpdateInvAttribute", player, item_id, modified_attributes, new_data)
	else:
		var item_attributes = player.get_attrib("mount_attributes." + key)
		var new_data = str2var(var2str(item_attributes[mount_idx]))
		var previous_variation = new_data.get("previous_variation", "")
		if not previous_variation.empty():
			default_variation = previous_variation
			new_data.erase("previous_variation")
		new_data["selected_variation"] = default_variation
		BehaviorEvents.emit_signal("OnUpdateMountAttribute", player, key, mount_idx, new_data)
		
	BehaviorEvents.emit_signal("OnLogLine", "%s has been successfully repaired!", [self.get_display_name(item_data, modified_attributes)])
	BehaviorEvents.emit_signal("OnValidateConsumption", player, triggering_data.item_data, triggering_data.key, triggering_data.attrib)
	
func GenerateAttributesFromInventory(item_src):
	var modified_attributes = {}
	var item_data = Globals.LevelLoaderRef.LoadJSON(item_src)
	var variations = Globals.get_data(item_data, "variations", [])
	if variations.size() > 0:
		modified_attributes = {"selected_variation":MersenneTwister.rand_weight(variations, "src", "chance")}
		
	if item_data.get("converter", null) != null:
		var recipe_variations = []
		var recipes = Globals.get_data(item_data, "converter.recipes", [])
		for index in range(recipes.size()):
			var recipe = recipes[index]
			var variation_src = ""
			if ".json" in recipe.produce:
				var recipe_data = Globals.LevelLoaderRef.LoadJSON(recipe.produce)
				var item_variations = Globals.get_data(recipe_data, "variations", [])
				if item_variations.size() > 0:
					variation_src = MersenneTwister.rand_weight(item_variations, "src", "chance")
			recipe_variations.push_back(variation_src)
	
		if recipe_variations.size() > 0:
			Globals.set_data(modified_attributes, "converter.selected_variations", recipe_variations)
	return modified_attributes
	

func process_recipes_attributes(obj):
	var recipe_variations = obj.get_attrib("converter.selected_variations", null)
	if recipe_variations != null:
		return
		
	recipe_variations = []
	var recipes = obj.get_attrib("converter.recipes", [])
	for index in range(recipes.size()):
		var recipe = recipes[index]
		var variation_src = ""
		if ".json" in recipe.produce:
			var recipe_data = Globals.LevelLoaderRef.LoadJSON(recipe.produce)
			var variations = Globals.get_data(recipe_data, "variations", [])
			if variations.size() > 0:
				variation_src = MersenneTwister.rand_weight(variations, "src", "chance")
		recipe_variations.push_back(variation_src)
		
	obj.set_attrib("converter.selected_variations", recipe_variations)

func SetCooldown(obj, item_attributes, cooldown, name_id):
	var mod_cooldown = cooldown * GetMultiplierValue(obj, "", item_attributes, "cooldown_multiplier")
	item_attributes["cooldown_turn"] = Globals.total_turn + cooldown
	var delayed_logs : Array = obj.get_attrib("delayed_logs", [])
	var msg_choices = {
		"%s is ready for action":50,
		"%s fully recharged":50,
		"%s cooldown completed":50
	}
	delayed_logs.push_back({"msg_turn": item_attributes["cooldown_turn"], "msg":msg_choices, "msg_params":[name_id]})
	obj.set_attrib("delayed_logs", delayed_logs)
	
	
func IsInCooldown(obj, item_attributes) -> bool:
	return item_attributes.get("cooldown_turn", Globals.total_turn) > Globals.total_turn
	
func GetRemainingCooldown(obj, item_attributes) -> float:
	return item_attributes.get("cooldown_turn", Globals.total_turn) - Globals.total_turn
	
#TODO: might want to cache the results until an event request a refresh
#		if all the params are the same, the result should be the same as long as
#		no equipment changed
func GetMultiplierValue(obj, item_src, item_attributes, attrib_base_name) -> float:
	return _get_value(obj, item_src, item_attributes, attrib_base_name, COMPOUNDING_TYPE.multiply, 1.0)
	
	
func GetBonusValue(obj, item_src, item_attributes, attrib_base_name) -> float:
	return _get_value(obj, item_src, item_attributes, attrib_base_name, COMPOUNDING_TYPE.add, 0.0)
	

func _get_value(obj, item_src, item_attributes, attrib_base_name, compound_type=COMPOUNDING_TYPE.multiply, initial_value=1.0) -> float:
	# effects struct : {"src":"bleh.json", "self_shield_multiplier":1.5, "self_energy_cost":1.3}
	if item_attributes == null:
		item_attributes = {}
	var result : float = initial_value
	var effects = []
	if obj == null:
		var variation_src = item_attributes.get("selected_variation")
		if variation_src != null and not variation_src.empty():
			var variation_data : Dictionary = Globals.LevelLoaderRef.LoadJSON(variation_src)
			var attrib = str2var(var2str(variation_data["attributes"]))
			attrib["src"] = variation_src
			effects = [attrib]
	else:
		effects = obj.get_attrib("applied_effects", [])
	var linked_effects = []
	var self_effects = []
	var debug_applied = []
	for effect in effects:
		var keys = effect.keys()
		for key in keys:
			# Not the attribute we're looking for
			if not attrib_base_name in key:
				continue
			
			# Fastest check first. Global stuff is always applied if it matches the base name
			if "global_" in key:
				if compound_type == COMPOUNDING_TYPE.add:
					result = result + effect[key]
				elif compound_type == COMPOUNDING_TYPE.multiply:
					result = result * effect[key]
				else:
					result = result - effect[key]
				debug_applied.push_back(effect.src)
				continue
			
			# Only apply first instance of a "self_" attribute, one item cannot possibly have multiple time the same variant
			if "self_" in key and effect.src == item_attributes.get("selected_variation") and not effect.src in self_effects:
				if compound_type == COMPOUNDING_TYPE.add:
					result = result + effect[key]
				elif compound_type == COMPOUNDING_TYPE.multiply:
					result = result * effect[key]
				else:
					result = result - effect[key]
				self_effects.push_back(effect.src)
				debug_applied.push_back(effect.src)
				continue
				
			if "mount_" in key:
				var item_data = Globals.LevelLoaderRef.LoadJSON(effect.src)
				if Globals.get_data(item_data, "equipment.slot", "") in attrib_base_name:
					if compound_type == COMPOUNDING_TYPE.add:
						result = result + effect[key]
					elif compound_type == COMPOUNDING_TYPE.multiply:
						result = result * effect[key]
					else:
						result = result - effect[key]
					debug_applied.push_back(effect.src)
					continue
				
			# Linked is basically the opposite of self_. We skip it once assuming it's us. Then we apply the "others" bonus
			if "linked_" in key and effect.src == item_attributes.get("selected_variation") and not effect.src in linked_effects:
				linked_effects.push_back(effect.src)
				continue
				
			if "linked_" in key and effect.src == item_attributes.get("selected_variation") and effect.src in linked_effects:
				if compound_type == COMPOUNDING_TYPE.add:
					result = result + effect[key]
				elif compound_type == COMPOUNDING_TYPE.multiply:
					result = result * effect[key]
				else:
					result = result - effect[key]
				debug_applied.push_back(effect.src)
				continue
	
	#obj, item_src, item_attributes, attrib_base_name
#	if debug_applied.size() > 0:
#		var obj_id = obj.get_attrib("unique_id")
#		var obj_name = obj.get_attrib("name_id")
#		var debug_msg = "Applied Effect " + attrib_base_name + " : " + str(result) + " ("
#		for t in debug_applied:
#			debug_msg += t + ","
#		debug_msg += ")"
#		print(debug_msg)
	
	return result

