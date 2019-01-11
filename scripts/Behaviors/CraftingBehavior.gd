extends Node

# recipe_data = {"name": "Energy", "requirements": [{"type":"food", "amount":1}], "produce":"energy", "amount":1500}
# input_list = ["data/json/items/weapons/missile.json", "data/json/items/weapons/missile.json", ...]
# crafter = Node with Attributes.gd
func Craft(recipe_data, input_list, crafter):
	# Init, Read and load data we will need
	var loaded_input_data = []
	var result = Globals.CRAFT_RESULT.success
	for item in input_list:
		if typeof(item) == TYPE_STRING and item == "energy":
			loaded_input_data.push_back({"type":"energy"})
		else:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			loaded_input_data.push_back({"data":data, "type":data["type"], "src":item.src, "amount":item.count})
	var can_produce = true
	var cur_energy = crafter.get_attrib("converter.stored_energy")
	var net_energy_change = 0
	
	# Validate that we can produce the thing
	for require in recipe_data.requirements:
		can_produce = false
		if "type" in require: # might eventually support other like "name_id"
			for info in loaded_input_data:
				if require["type"] == "energy" and info.type == "energy":
					if cur_energy < require["amount"]:
						result = Globals.CRAFT_RESULT.not_enough_energy
						break
					can_produce = true
					continue
				elif info["type"] == require["type"]:
					if info["amount"] < require["amount"]:
						result = Globals.CRAFT_RESULT.not_enough_resources
						break
					can_produce = true
					continue
		if can_produce == false:
			if result == Globals.CRAFT_RESULT.success:
				result = Globals.CRAFT_RESULT.missing_resources
			return result
		
	# Consume Resources
	for require in recipe_data.requirements:
		if "type" in require: # might eventually support other like "name_id"
			for info in loaded_input_data:
				if require["type"] == "energy" and info.type == "energy":
					net_energy_change -= require["amount"]
					continue
				elif info["type"] == require["type"]:
					for i in range(require["amount"]):
						BehaviorEvents.emit_signal("OnRemoveItem", crafter, info["src"])
					continue
	
	# Produce the thing
	if recipe_data.produce == "energy":
		net_energy_change += recipe_data.amount
	else:
		for i in range(recipe_data.amount):
			BehaviorEvents.emit_signal("OnAddItem", crafter, recipe_data.produce)
	
	BehaviorEvents.emit_signal("OnUseEnergy", crafter, -net_energy_change)
	BehaviorEvents.emit_signal("OnUseAP", crafter, recipe_data.ap_cost)
	return result