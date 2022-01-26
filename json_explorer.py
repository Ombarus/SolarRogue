import sys
import os
os.environ["path"] = os.path.dirname(sys.executable) + ";" + os.environ["path"]
import glob
import numpy
import json

###############################################################################
# GLOBAL CONSTANTS
###############################################################################


DATA_FOLDER = "data"
PRINT_LEVEL=2


###############################################################################
# UTILITIES
###############################################################################


def myprint(str, level=0):
	if (level >= PRINT_LEVEL):
		print(str)
		
def print_as_csv(table, level=0):
	if (level < PRINT_LEVEL):
		return
	
	print("------")
	for row in table:
		msg = ""
		for col in row:
			msg += "\"" + str(col) + "\","
		print(msg[0:-1])
	print("------")
	
	
def clean_path(path):
	path = path.replace("\\", "/")
	return path

###############################################################################
# MAIN
###############################################################################

def glob_json(params):
	root = os.path.join(params["glob_root"], "**", "*.json")
	myprint("Loading jsons in " + root, 3)
	all_json = glob.glob(root, recursive=True)
	loaded_jsons = []
	for json_file in all_json:
		myprint("processing " + json_file)
		with open(json_file, 'r') as jsonfile:
			data = json.load(jsonfile)
			data["src"] = clean_path(json_file)
		loaded_jsons.append(data)
	myprint("Loaded " + str(len(loaded_jsons)) + " jsons", 1)
	params["data"] = loaded_jsons

		
def crafting_report(params):
	
	#"recyclable": {
	#	"energy": 1200,
	#	"player_sale_range": [1900,2200],
	#	"player_buy_range": [2800,3500]
	#},
	#"disassembling": {
	#	"produce":"data/json/items/misc/spare_parts.json",
	#	"count":4,
	#	"energy_cost":1000
	#},
	
	#"converter": {
	#	"maximum_energy":40000,
	#	"recipes": [
	
	#{
	#	"name": "Laser Turret MK2", 
	#	"requirements":[{"type":"energy", "amount":1000}, {"type":"spare_parts", "amount":4}], 
	#	"produce":"data/json/items/weapons/laser_turret_mk2.json",
	#	"ap_cost":5.0,
	#	"amount":1
	#},
	
	result = [["name_id", "recyclable_energy", "sale_range", "buy_range", "disassemble_parts", "disassemble_cost", "ap_cost", "energy_cost", "spare_parts_cost"]]
	
	for object in params["data"]:
		name_id = object["name_id"]
		has_some_data = False
		myprint("processing " + name_id)
		recyclable_energy = "N/A"
		recyclable_sale = "N/A"
		recyclable_buy = "N/A"
		disassemble_count = "-1"
		disassemble_energy = "-1"
		if "recyclable" in object:
			has_some_data = True
			recyclable_data = object["recyclable"]
			recyclable_energy = str(recyclable_data["energy"])
			recyclable_sale = str(recyclable_data["player_sale_range"])
			recyclable_buy = str(recyclable_data["player_buy_range"])
		if "disassembling" in object:
			has_some_data = True
			disassembling_data = object["disassembling"]
			disassemble_count = str(disassembling_data["count"])
			disassemble_energy = str(disassembling_data["energy_cost"])
			
			
			
		ap_cost = -1
		energy_cost = -1
		spare_parts_cost = -1
		for converter in params["data"]:
			if "converter" in converter and "recipes" in converter["converter"]:
				recipes = converter["converter"]["recipes"]
				for recipe in recipes:
					produce = clean_path(recipe["produce"])
					if produce in object["src"]:
						has_some_data = True
						if ap_cost > 0 and ap_cost != recipe["ap_cost"]:
							myprint("************ERROR in {}, ap_cost seen twice ({},{})".format(name_id, str(ap_cost), str(recipe["ap_cost"])), 10)
						ap_cost = recipe["ap_cost"]
						for req in recipe["requirements"]:
							if "type" in req and req["type"] == "energy":
								if energy_cost > 0 and energy_cost != req["amount"]:
									myprint("************ERROR in {}, energy_cost seen twice ({},{})".format(name_id, str(energy_cost), str(req["amount"])), 10)
								energy_cost = req["amount"]
							if "type" in req and req["type"] == "spare_parts":
								if spare_parts_cost > 0 and spare_parts_cost != req["amount"]:
									myprint("************ERROR in {}, spare_parts_cost seen twice ({},{})".format(name_id, str(spare_parts_cost), str(req["amount"])), 10)
								spare_parts_cost = req["amount"]
							
						
		if has_some_data:
			result.append([
				name_id, 
				str(recyclable_energy), 
				str(recyclable_sale),
				str(recyclable_buy),
				str(disassemble_count),
				str(disassemble_energy),
				str(ap_cost),
				str(energy_cost),
				str(spare_parts_cost)
			])
			
	print_as_csv(result)
	
	
def weapon_energy_report(params):
	#"weapon_data": {
	#	"base_dam":8.0,
	#	"max_dam":12.0,
	#	"fire_range":3.0,
	#	"fire_pattern":"+",
	#	"fire_energy_cost":750.0,
	#	"fire_speed":1.0
	#},
	
	
	# for each weapon
	#1. how much energy to fire
	#2. if ammo, how much energy to produce ammo
	#3. ap_shot
	#4. min_dam, max_dam
	
	result = [["name_id", "fire_cost", "ammo_cost", "ap", "min_dam", "max_dam", "range"]]
	for object in params["data"]:
		name_id = object["name_id"]
		myprint("processing " + name_id)
		
		fire_cost = 0
		ammo_cost = 0
		ap_cost = 0
		min_dam = 0
		max_dam = 0
		range = 0
		has_some_data = False
		
		if "weapon_data" in object:
			weapon_data = object["weapon_data"]
			has_some_data = True
			min_dam = weapon_data["base_dam"]
			max_dam = weapon_data["max_dam"]
			range = weapon_data["fire_range"]
			ap_cost = weapon_data["fire_speed"]
			fire_cost = weapon_data["fire_energy_cost"]
			if "ammo" in weapon_data:
				for converter in params["data"]:
					if "converter" in converter and "recipes" in converter["converter"]:
						recipes = converter["converter"]["recipes"]
						for recipe in recipes:
							produce = clean_path(recipe["produce"])
							if produce in weapon_data["ammo"]:
								for req in recipe["requirements"]:
									if "type" in req and req["type"] == "energy":
										if ammo_cost > 0 and ammo_cost != req["amount"]:
											myprint("************ERROR in {}, ammo_cost seen twice ({},{})".format(name_id, str(ammo_cost), str(req["amount"])), 10)
										ammo_cost = req["amount"]
				
		if has_some_data:
			result.append([
				name_id, 
				str(fire_cost), 
				str(ammo_cost),
				str(ap_cost),
				str(min_dam),
				str(max_dam),
				str(range)
			])
		
	print_as_csv(result)
		
		
def converter_recipe_report(params):
	# for each json objects
		# collect converter & recipes
		# add column header
	# for each json objects
		# check if it is in any converter
			# if not print warning
			# if it is, add a row
	
	converter_list = []
	header = ["name_id"]
	for converter in params["data"]:
		name_id = converter["name_id"]
		if "converter" in converter and "recipes" in converter["converter"]:
			converter_list.append(converter)
			header.append(name_id)
			
	result = [header]
	for object in params["data"]:
		name_id = object["name_id"]
		print("processing " + object["src"])
		in_any_converter = False
		row_data = [name_id]
		for converter in converter_list:
			recipes = converter["converter"]["recipes"]
			in_this_converter = False
			for recipe in recipes:
				produce = clean_path(recipe["produce"])
				if produce in object["src"]:
					print("converter {} : produce {} matches {}".format(converter["name_id"], produce, object["src"]))
					in_any_converter = True
					in_this_converter = True
					row_data.append("O")
			if not in_this_converter:
				row_data.append("X")
		if in_any_converter:
			result.append(row_data)
		else:
			myprint("WARNING: {} not in any converter".format(name_id), 5)
			
	print_as_csv(result)		
	
def count_mounts(params):
	for ship in params["data"]:
		name_id = ship["name_id"]
		if "mounts" in ship:
			if "mount_attributes" not in ship:
				myprint("WARNING: {} is missing mount_attributes".format(name_id))
				continue
			checklist = ["weapon", "shield", "scanner", "converter", "utility"]
			for m in checklist:
				if m in ship["mounts"]:
					if m not in ship["mount_attributes"]:
						myprint("WARNING: {} is missing {} in mount_attributes".format(name_id, m))
						if len(ship["mount_attributes"][m]) != len(ship["mounts"][m]):
							myprint("ERROR: {} {} count doesn't match in mount_attributes".format(name_id, m))
	

def search_invalid_filename(params):
	for f in params["data"]:
		search_dict(f)
		
def search_dict(root):
	for comp in root:
		comp_val = root[comp]
		if type(comp_val) is dict:
			search_dict(comp_val)
		elif type(comp_val) is list:
			search_list(comp_val)
		elif type(comp_val) is str:
			if "json" in comp_val or "tscn" in comp_val:
				if not os.path.exists(comp_val):
					myprint("ERROR: File not found {}".format(comp_val), 5)

def search_list(root):
	for comp_val in root:
		if type(comp_val) is dict:
			search_dict(comp_val)
		elif type(comp_val) is list:
			search_list(comp_val)
		elif type(comp_val) is str:
			if "json" in comp_val or "tscn" in comp_val:
				if not os.path.exists(comp_val):
					myprint("ERROR: File not found {}".format(comp_val), 5)
	
def list_types(params):
	types = {}
	for f in params["data"]:
		if "type" in f:
			if f["type"] not in types:
				types[f["type"]] = 1
			else:
				types[f["type"]] += 1
			
	print(types)
	
def shield_hull_report(params):
	ship_list = []
	shield_list = []
	
	for f in params["data"]:
		if "type" in f:
			if f["type"] == "ship" and "boardable" in f and f["boardable"] == True:
				max_shield = 0
				if "shield" in f["mounts"]:
					max_shield = len(f["mounts"]["shield"])
				ship_list.append({
					"name":f["name_id"], 
					"max_shields":max_shield,
					"hull":f["destroyable"]["hull"]
				})
			if f["type"] == "shield":
				shield_list.append({"name":f["name_id"], "shield":f["shielding"]["max_hp"]})
				
	csv_result = [["setup", "hull", "shield", "total"]]
	for ship in ship_list:			
			setup_name = "{} only".format(ship["name"])
			csv_result.append([setup_name, ship["hull"], 0, ship["hull"]])
			if ship["max_shields"] > 0:
				for shield in shield_list:
					# 1, 0.5, 0.25, 0.125, etc.
					count = 0
					shield_hp_sum = 0
					for i in range(ship["max_shields"]):
						shield_hp_sum += shield["shield"] / pow(2, count)
						count += 1
					setup_name = "{} + {}".format(ship["name"], shield["name"])
					csv_result.append([setup_name, ship["hull"], shield_hp_sum, ship["hull"] + shield_hp_sum])
	
	print(len(csv_result))
	print_as_csv(csv_result, 5)
	
	
def shield_hull_report_mob(params):
	ship_list = []
	shield_list = {}
	
	for f in params["data"]:
		if "type" in f:
			if f["type"] == "ship" and "ai" in f and "aggressive" in f["ai"] and f["ai"]["aggressive"] == True:
				mob_shields = []
				if "shield" in f["mounts"]:
					mob_shields = f["mounts"]["shield"]
				ship_list.append({
					"name":f["name_id"], 
					"max_shields":mob_shields,
					"hull":f["destroyable"]["hull"]
				})
			if f["type"] == "shield":
				shield_list[f["src"]] = f["shielding"]["max_hp"]
				
	csv_result = [["mob name", "hull", "shield", "total"]]
	print(shield_list)
	for ship in ship_list:			
			setup_name = "{}".format(ship["name"])
			shield_hp_sum = 0
			count = 0
			for mob_shield_src in ship["max_shields"]:
				if mob_shield_src != "":
					shield_hp_sum += shield_list[mob_shield_src]/ pow(2, count)
					count += 1
			csv_result.append([setup_name, ship["hull"], shield_hp_sum, ship["hull"] + shield_hp_sum])
	
	print(len(csv_result))
	print_as_csv(csv_result, 5)
			
		
def do_actions(actions, params):
	if "glob_json" in actions:
		glob_json(params)
	if "crafting_report" in actions:
		crafting_report(params)
	if "weapon_energy_report" in actions:
		weapon_energy_report(params)
	if "converter_recipe_report" in actions:
		converter_recipe_report(params)
	if "count_mounts" in actions:
		count_mounts(params)
	if "search_invalid_filename" in actions:
		search_invalid_filename(params)
	if "list_types" in actions:
		list_types(params)
	if "shield_hull_report" in actions:
		shield_hull_report(params)
	if "shield_hull_report_mob" in actions:
		shield_hull_report_mob(params)
		
		
if __name__ == '__main__':
	actions = [
		"glob_json",
		#"search_invalid_filename",
		#"shield_hull_report", # Create a list of ship + shield = how much HP (Was trying to figure out how to know a ship is under-leveled for it's current depth)
		"shield_hull_report_mob", # Create a list of ship + shield = how much HP (Was trying to figure out how to know a ship is under-leveled for it's current depth)
		#"count_mounts",
		#"crafting_report",
		#"weapon_energy_report",
		#"converter_recipe_report",
		#"list_types",
		"nothing" # just so I don't need to play with the last ,
	]
	params = {
		"glob_root":os.path.join(DATA_FOLDER, "json"),
		"nothing" : None # don't have to deal with last ,
	}
	do_actions(actions, params)