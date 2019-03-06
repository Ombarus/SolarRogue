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
			loaded_input_data.push_back({"type":"energy", "src":""})
		else:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			loaded_input_data.push_back({"data":data, "type":data["type"], "src":item.src, "amount":item.count})
	var can_produce = true
	var cur_energy = crafter.get_attrib("converter.stored_energy")
	var net_energy_change = 0
	
	var num_produced = 0
	
	# Produce as many as the input_list allows
	while (can_produce == true):
		result = Globals.CRAFT_RESULT.success
		# Validate that we can produce the thing
		for require in recipe_data.requirements:
			can_produce = false
			if recipe_data.produce == "energy":
				for info in loaded_input_data:
					if info.type == "energy":
						continue
					if info["amount"] > 0:
						can_produce = true
						break
			elif "type" in require: # might eventually support other like "name_id"
				for info in loaded_input_data:
					if require["type"] == "energy" and info.type == "energy":
						if (cur_energy+net_energy_change) < require["amount"]:
							result = Globals.CRAFT_RESULT.not_enough_energy
							break
						can_produce = true
						continue
					elif info["type"] == require["type"]:
						if info["amount"] < require["amount"]:
							result = Globals.CRAFT_RESULT.not_enough_resources
						else:
							can_produce = true
						continue
			elif "src" in require:
				#TODO: count how many are required (take into account stackable ?)
				for info in loaded_input_data:
					if Globals.clean_path(require["src"]) in Globals.clean_path(info["src"]):
						if info["amount"] < require["amount"]:
							result = Globals.CRAFT_RESULT.not_enough_resources
							#break
						else:
							can_produce = true
						continue
			if can_produce == false:
				if result == Globals.CRAFT_RESULT.success:
					result = Globals.CRAFT_RESULT.missing_resources
				break
				
		if can_produce == false:
			break
		else:
			result = Globals.CRAFT_RESULT.success
			
		# Consume Resources
		var consumed_data = []
		for require in recipe_data.requirements:
			if recipe_data.produce == "energy":
				for info in loaded_input_data:
					if info.type == "energy":
						continue
					if info["amount"] > 0:
						BehaviorEvents.emit_signal("OnRemoveItem", crafter, info["src"])
						consumed_data.push_back({"data":info.data, "amount":require["amount"]})
						info.amount -= require["amount"] # this works if "amount" is 1... but might cause issues if more
			elif "type" in require:
				for info in loaded_input_data:
					if require["type"] == "energy" and info.type == "energy":
						net_energy_change -= require["amount"]
						break
					elif info["type"] == require["type"] and info["amount"] > 0:
						for i in range(require["amount"]):
							BehaviorEvents.emit_signal("OnRemoveItem", crafter, info["src"])
							info.amount -= 1
						break
			elif "src" in require:
				for info in loaded_input_data:
					if Globals.clean_path(info["src"]) == Globals.clean_path(require["src"]) and info["amount"] > 0:
						for i in range(require["amount"]):
							BehaviorEvents.emit_signal("OnRemoveItem", crafter, info["src"])
							info.amount -= 1
						break
		
		# Produce the thing
		if recipe_data.produce == "energy":
			for d in consumed_data:
				net_energy_change += d.data.recyclable.energy * d.amount
		else:
			var product_data = Globals.LevelLoaderRef.LoadJSON(recipe_data.produce)
			for i in range(recipe_data.amount):
				if not "equipment" in product_data:
					Globals.LevelLoaderRef.RequestObject(recipe_data.produce, Globals.LevelLoaderRef.World_to_Tile(crafter.position))
				else:
					BehaviorEvents.emit_signal("OnAddItem", crafter, recipe_data.produce)
		
		
		num_produced += 1
		# Really weird use case for missile that only require energy. Produce only one at a time
		if recipe_data.requirements.size() == 1 and "type" in recipe_data.requirements[0] and recipe_data.requirements[0].type == "energy":
			can_produce = false
			
	if num_produced > 0:
		BehaviorEvents.emit_signal("OnUseAP", crafter, recipe_data.ap_cost * num_produced)
		BehaviorEvents.emit_signal("OnUseEnergy", crafter, -net_energy_change)
		result = Globals.CRAFT_RESULT.success
	return result