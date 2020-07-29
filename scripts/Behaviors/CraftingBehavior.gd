extends Node

# recipe_data = {"name": "Energy", "requirements": [{"type":"food", "amount":1}], "produce":"energy", "amount":1500}
# input_list = ["data/json/items/weapons/missile.json", "data/json/items/weapons/missile.json", ...]
# crafter = Node with Attributes.gd

func LoadInput(var input_list : Array) -> Array:
	var loaded_input_data = []
	for item in input_list:
		if "disabled" in item and item.disabled == true:
			continue
		if typeof(item) == TYPE_STRING and item == "energy":
			loaded_input_data.push_back({"type":"energy", "src":""})
		else:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			loaded_input_data.push_back({"data":data, "type":data["type"], "src":item.src, "amount":item.selected})
	return loaded_input_data


func TestRequirements(var recipe_data : Dictionary, var loaded_input_data : Array, var energy_budget : float, var missing_out = null):
	var can_produce = true
	var src_requirements := []
	var type_requirements := []
	var energy_requirements := 0.0
	if missing_out == null:
		missing_out = []
	
	# Complete exception if 'recycling' energy instead of producing items
	if recipe_data.produce == "energy":
		can_produce = false
		for input_data in loaded_input_data:
			if input_data.type == "energy":
				continue
			if input_data["amount"] > 0:
				can_produce = true
				break
		return can_produce
		
	# Another exception for disassembling spare_parts
	if recipe_data.produce == "spare_parts":
		can_produce = false
		for input_data in loaded_input_data:
			if input_data.type == "energy":
				continue
			if input_data["amount"] > 0:
				can_produce = true
				energy_requirements += input_data.data.disassembling.energy_cost * input_data["amount"]
				break
		if energy_budget <= energy_requirements:
			can_produce = false
			missing_out.push_back({"type":"energy", "src":""})
		return can_produce
			
	
	# go from most specific to most generic so we make sure we don't use a specific item as a generic item
	# if another generic item could have been used freing the specific item for src requirements
	for require in recipe_data.requirements:
		if "src" in require:
			src_requirements.push_back(require)
		elif "type" in require:
			if require["type"] == "energy":
				energy_requirements = require["amount"]
			else:
				type_requirements.push_back(require)
	
	for input_data in loaded_input_data:
		input_data["will_consume"] = 0
	
	for require in src_requirements:
		var total_needed : int = require["amount"]
		for input_data in loaded_input_data:
			if Globals.clean_path(require["src"]) in Globals.clean_path(input_data["src"]):
				var holding = input_data["amount"]
				if "will_consume" in input_data:
					holding -= input_data["will_consume"]
				if holding >= 0:
					input_data["will_consume"] += min(total_needed, holding)
					total_needed -= min(total_needed, holding)
		if total_needed > 0:
			missing_out.push_back(require)
			
	for require in type_requirements:
		var total_needed : int = require["amount"]
		for input_data in loaded_input_data:
			if input_data["type"] == require["type"]:
				var holding = input_data["amount"]
				if "will_consume" in input_data:
					holding -= input_data["will_consume"]
				if holding >= 0:
					input_data["will_consume"] += min(total_needed, holding)
					total_needed -= min(total_needed, holding)
		if total_needed > 0:
			missing_out.push_back(require)
			
	if energy_budget <= energy_requirements:
		missing_out.push_back({"type":"energy", "src":""})
		
	if missing_out.size() > 0:
		return false
	else:
		return true
	
	
func Craft(recipe_data, input_list, crafter):
	# Init, Read and load data we will need
	var loaded_input_data := LoadInput(input_list)
	var result = Globals.CRAFT_RESULT.not_enough_resources # kinda obsolete since the UI won't let you try to craft stuff if you don't have the requirements
	var can_produce = true
	var cur_energy = crafter.get_attrib("converter.stored_energy")
	var net_energy_change = 0
	
	var num_produced = 0
	
	# Produce as many as the input_list allows
	while (can_produce == true):
		result = Globals.CRAFT_RESULT.success
		# Validate that we can produce the thing
		can_produce = TestRequirements(recipe_data, loaded_input_data, cur_energy+net_energy_change)
		if can_produce == false:
			break
			
		# Consume Resources
		var consumed_data = []
		for require in recipe_data.requirements:
			if recipe_data.produce == "energy":
				for info in loaded_input_data:
					if info.type == "energy":
						continue
					if info["amount"] > 0:
						BehaviorEvents.emit_signal("OnRemoveItem", crafter, info["src"], info.get("modified_attributes", {}))
						consumed_data.push_back({"data":info.data, "amount":require["amount"]})
						info.amount -= require["amount"] # this works if "amount" is 1... but might cause issues if more
			elif recipe_data.produce == "spare_parts":
				for info in loaded_input_data:
					if info.type == "energy":
						continue
					if info["amount"] > 0:
						BehaviorEvents.emit_signal("OnRemoveItem", crafter, info["src"], info.get("modified_attributes", {}))
						consumed_data.push_back({"data":info.data, "amount":require["amount"]})
						info.amount -= require["amount"] # this works if "amount" is 1... but might cause issues if more
			elif "type" in require:
				var consumed = 0
				for info in loaded_input_data:
					if require["type"] == "energy" and info.type == "energy":
						net_energy_change -= require["amount"]
						break
					elif info["type"] == require["type"] and info["amount"] > 0:
						for i in range(min(require["amount"], info["amount"])):
							BehaviorEvents.emit_signal("OnRemoveItem", crafter, info["src"], info.get("modified_attributes", {}))
							consumed += 1
							info.amount -= 1
						if consumed >= require["amount"]:
							break
			elif "src" in require:
				var consumed = 0
				for info in loaded_input_data:
					if Globals.clean_path(info["src"]) == Globals.clean_path(require["src"]) and info["amount"] > 0:
						for i in range(min(require["amount"], info["amount"])):
							BehaviorEvents.emit_signal("OnRemoveItem", crafter, info["src"], info.get("modified_attributes", {}))
							consumed += 1
							info.amount -= 1
						if consumed >= require["amount"]:
							break
		
		# Produce the thing
		if recipe_data.produce == "spare_parts":
			for d in consumed_data:
				net_energy_change -= d.data.disassembling.energy_cost * d.amount
				for i in range(d.data.disassembling.count):
					BehaviorEvents.emit_signal("OnAddItem", crafter, d.data.disassembling.produce, {})
		elif recipe_data.produce == "energy":
			for d in consumed_data:
				net_energy_change += d.data.recyclable.energy * d.amount
		else:
			var product_data = Globals.LevelLoaderRef.LoadJSON(recipe_data.produce)
			for i in range(recipe_data.amount):
				if not "equipment" in product_data:
					Globals.LevelLoaderRef.RequestObject(recipe_data.produce, Globals.LevelLoaderRef.World_to_Tile(crafter.position))
				else:
					BehaviorEvents.emit_signal("OnAddItem", crafter, recipe_data.produce, {})
		
		
		num_produced += 1
		# Really weird use case for missile that only require energy. Produce only one at a time
		if recipe_data.requirements.size() == 1 and "type" in recipe_data.requirements[0] and recipe_data.requirements[0].type == "energy":
			can_produce = false
			
	if num_produced > 0:
		BehaviorEvents.emit_signal("OnUseAP", crafter, recipe_data.ap_cost * num_produced)
		BehaviorEvents.emit_signal("OnUseEnergy", crafter, -net_energy_change)
		result = Globals.CRAFT_RESULT.success
	BehaviorEvents.emit_signal("OnCrafting", crafter, result)
	return result
