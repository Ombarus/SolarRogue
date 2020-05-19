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
PRINT_LEVEL=0


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
	
	
		
def do_actions(actions, params):
	if "glob_json" in actions:
		glob_json(params)
	if "crafting_report" in actions:
		crafting_report(params)
		
		
if __name__ == '__main__':
	actions = [
		"glob_json",
		"crafting_report",
		"nothing" # just so I don't need to play with the last ,
	]
	params = {
		"glob_root":os.path.join(DATA_FOLDER, "json"),
		"nothing" : None # don't have to deal with last ,
	}
	do_actions(actions, params)