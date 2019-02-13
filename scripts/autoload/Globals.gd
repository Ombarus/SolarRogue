extends Node

var LevelLoaderRef = null
var last_delta_turn = 0
var total_turn = 0

enum CRAFT_RESULT {
	success,
	not_enough_resources,
	not_enough_energy,
	missing_resources
}

enum VALID_TARGET {
	attack,
	loot,
	board
}

# Copy-pasta from Attribute.gd, but with enough small changes that I'm not sure I want to unify this
func get_data(obj, path, default=null):
	if obj == null:
		return default
	var splices = path.split(".", false)
	var sub = obj
	for s in splices:
		if sub.has(s):
			sub = sub[s]
			if typeof(sub) == TYPE_DICTIONARY and sub.has("disabled") and sub["disabled"] == true:
				return default
		else:
			sub = null
			break
	return _check_data(sub, default)
	
func _check_data(val, default):
	if typeof(val) == TYPE_DICTIONARY and val.has("__class"):
		return str2var(val.value)
	else:
		if val == null:
			return default
		else:
			return val
