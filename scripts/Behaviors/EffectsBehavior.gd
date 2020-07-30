extends Node
class_name EffectBehavior


func _ready():
	Globals.EffectRef = self
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	
func _exit_tree():
	Globals.EffectRef = null

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
	effect_data = str2var(var2str(effect_data))
	
	effect_data["src"] = variation_src
	var applied_effects : Array = obj.get_attrib("applied_effects", [])
	applied_effects.push_back(effect_data)
	obj.set_attrib("applied_effects", applied_effects)
	
	
func OnMountRemoved_Callback(obj, slot, src, modified_attributes):
	if modified_attributes == null or not modified_attributes.has("selected_variation"):
		return
		
	var variation_src : String = Globals.clean_path(modified_attributes.get("selected_variation"))
	var applied_effects : Array = obj.get_attrib("applied_effects", [])
	for effect in applied_effects:
		if Globals.clean_path(effect.src) == variation_src:
			applied_effects.remove(effect)
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
	for effect in effects:
		var keys = effect.keys()
		for key in keys:
			# Not the attribute we're looking for
			if not attrib_base_name in key:
				continue
			
			# Fastest check first. Global stuff is always applied if it matches the base name
			if "global_" in key:
				result = result * effect[key]
				continue	
			
			# Only apply first instance of a "self_" attribute, one item cannot possibly have multiple time the same variant
			if "self_" in key and effect.src == item_attributes.get("selected_variation") and not effect.src in applied_effects:
				result = result * effect[key]
				applied_effects.push_back(effect.src)
				continue
				
			# Linked is basically the opposite of self_. We skip it once assuming it's us. Then we apply the "others" bonus
			if "linked_" in key and effect.src == item_attributes.get("selected_variation") and not effect.src in applied_effects:
				applied_effects.push_back(effect.src)
				continue
				
			if "linked_" in key and effect.src == item_attributes.get("selected_variation") and effect.src in applied_effects:
				result = result * effect[key]
				continue
				
	return result
