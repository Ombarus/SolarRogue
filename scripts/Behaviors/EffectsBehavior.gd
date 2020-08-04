extends Node
class_name EffectBehavior

# Effects are implemeting their own, very confusing, DSL (Domain Specific Language)
# Effects have attributes dictionary. each key-value pair define an effect and the value of that effect
# ex : shield_multiplier define a multiplier to the shield value of a ship
# each effect can have prefixes that tell the game how the multiplier should be applied
# "self_" -> only apply effect to self (ex: weapon damage increase)
# "global_" -> apply to final result (ex: to all weapon damage or to global cargo capacity, etc.)
# "inv_" -> by default, apply only if item is equipped, use inv_ to specify effect applies from inventory too

# "inv_" is a bit special, it needs to be added separate from other effects
#		so we're going to create a duplicate of the attributes to add to effect list
#		but that also means we need a way to differenciate other than the name of the variation
#		so I'll add another id.

func _ready():
	Globals.EffectRef = self
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnPickObject", self, "OnPickObject_Callback")
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnAddItem", self, "OnAddItem_Callback")
	BehaviorEvents.connect("OnRemoveItem", self, "OnremoveItem_Callback")
	BehaviorEvents.connect("OnItemDropped", self, "OnItemDropped_Callback")
	
func _exit_tree():
	Globals.EffectRef = null
	
	
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
		

func OnMountAdded_Callback(obj, slot, src, modified_attributes):
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
	
	
func OnMountRemoved_Callback(obj, slot, src, modified_attributes):
	if modified_attributes == null or not modified_attributes.has("selected_variation"):
		return
		
	var variation_src : String = Globals.clean_path(modified_attributes.get("selected_variation"))
	var applied_effects : Array = obj.get_attrib("applied_effects", [])
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
		
	var variations = obj.get_attrib("variations", [])
	if variations.size() <= 0:
		return
		
	selected_variation = MersenneTwister.rand_weight(variations, "src", "chance")
	
	obj.set_attrib("selected_variation", selected_variation)
	

#TODO: might want to cache the results until an event request a refresh
#		if all the params are the same, the result should be the same as long as
#		no equipment changed
func GetMultiplierValue(obj, item_src, item_attributes, attrib_base_name) -> float:
	# effects struct : {"src":"bleh.json", "self_shield_multiplier":1.5, "self_energy_cost":1.3}
	if item_attributes == null:
		item_attributes = {}
	var result : float = 1.0
	var effects = obj.get_attrib("applied_effects", [])
	var applied_effects = []
	var debug_applied = []
	for effect in effects:
		var keys = effect.keys()
		for key in keys:
			# Not the attribute we're looking for
			if not attrib_base_name in key:
				continue
			
			# Fastest check first. Global stuff is always applied if it matches the base name
			if "global_" in key:
				result = result * effect[key]
				debug_applied.push_back(effect.src)
				continue
			
			# Only apply first instance of a "self_" attribute, one item cannot possibly have multiple time the same variant
			if "self_" in key and effect.src == item_attributes.get("selected_variation") and not effect.src in applied_effects:
				result = result * effect[key]
				applied_effects.push_back(effect.src)
				debug_applied.push_back(effect.src)
				continue
				
			# Linked is basically the opposite of self_. We skip it once assuming it's us. Then we apply the "others" bonus
			if "linked_" in key and effect.src == item_attributes.get("selected_variation") and not effect.src in applied_effects:
				applied_effects.push_back(effect.src)
				continue
				
			if "linked_" in key and effect.src == item_attributes.get("selected_variation") and effect.src in applied_effects:
				result = result * effect[key]
				debug_applied.push_back(effect.src)
				continue
	
	#obj, item_src, item_attributes, attrib_base_name
	if debug_applied.size() > 0:
		var obj_id = obj.get_attrib("unique_id")
		var obj_name = obj.get_attrib("name_id")
		var debug_msg = "Applied Effect " + attrib_base_name + " : " + str(result) + " ("
		for t in debug_applied:
			debug_msg += t + ","
		debug_msg += ")"
		print(debug_msg)
	
	return result
