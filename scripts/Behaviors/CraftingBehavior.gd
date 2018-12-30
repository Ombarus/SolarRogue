extends Node

func Craft(recipe_data, input_list, crafter):
	var loaded_data = []
	for item in input_list:
		if item == "energy":
			loaded_data.push_back("energy")
		else:
			loaded_data.push_back(Globals.LevelLoaderRef.LoadJSON(item))
	#for require in recipe_data.requirements:
	#	if "type" in require:
			