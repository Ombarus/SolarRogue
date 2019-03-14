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
	
	
func set_data(obj, path, val):
	var splices = path.split(".", false)
	var sub = obj
	for i in range(splices.size()-1):
		var s = splices[i]
		if not sub.has(s):
			sub[s] = {}
		sub = sub[s]

	if typeof(val) == TYPE_VECTOR2:
		val = {"__class":"Vector2", "value": var2str(val)}
	elif not typeof(val) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_REAL, TYPE_STRING, TYPE_DICTIONARY, TYPE_ARRAY]:
		print("warning: (", path,  " = ", val, ") trying to serialize an unknown type to JSON")
	
	sub[splices[-1]] = val
	
	
func _check_data(val, default):
	if typeof(val) == TYPE_DICTIONARY and val.has("__class"):
		return str2var(val.value)
	else:
		if val == null:
			return default
		else:
			return val
			
func clean_path(path):
	if not "res://" in path and not "user://" in path:
		path = "res://" + path
	
	return path
