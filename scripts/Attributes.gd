extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

export(String, FILE, "*.json") var PreloadData = ""
#TODO: hack to be able to modify modified_attributes in the editor. Apparently we can edit dictionnary in 3.1 so
# this shouldn't be needed in 3.1
export(String, MULTILINE) var PreloadJSON = ""

export var base_attributes = {} # can be kept by reference, no need to serialize
export var modified_attributes = {} # locally modified attribute (like current position). Should be saved !

func get_attrib(path, default=null):
	var splices = path.split(".", false)
	var sub = modified_attributes
	for s in splices:
		if sub.has(s):
			sub = sub[s]
			if typeof(sub) == TYPE_DICTIONARY and sub.has("disabled") and sub["disabled"] == true:
				return default
		else:
			sub = null
			break
	if sub != null:
		return Check(sub, default)
	sub = base_attributes
	for s in splices:
		if sub.has(s):
			sub = sub[s]
			if typeof(sub) == TYPE_DICTIONARY and sub.has("disabled") and sub["disabled"] == true:
				return default
		else:
			sub = null
			break
	return Check(sub, default)
	
func Check(val, default):
	if typeof(val) == TYPE_DICTIONARY and val.has("__class"):
		return str2var(val.value)
	else:
		if val == null:
			return default
		else:
			return val
	
func set_attrib(path, val):
	var splices = path.split(".", false)
	var sub = modified_attributes
	for i in range(splices.size()-1):
		var s = splices[i]
		if not sub.has(s):
			sub[s] = {}
		sub = sub[s]
	
	#TYPE_NIL = 0 — Variable is of type nil (only applied for null).
	#TYPE_BOOL = 1 — Variable is of type bool.
	#TYPE_INT = 2 — Variable is of type int.
	#TYPE_REAL = 3 — Variable is of type float/real.
	#TYPE_STRING = 4 — Variable is of type String.
	#TYPE_VECTOR2 = 5 — Variable is of type Vector2.
	#TYPE_RECT2 = 6 — Variable is of type Rect2.
	#TYPE_VECTOR3 = 7 — Variable is of type Vector3.
	#TYPE_TRANSFORM2D = 8 — Variable is of type Transform2D.
	#TYPE_PLANE = 9 — Variable is of type Plane.
	#TYPE_QUAT = 10 — Variable is of type Quat.
	#TYPE_AABB = 11 — Variable is of type AABB.
	#TYPE_BASIS = 12 — Variable is of type Basis.
	#TYPE_TRANSFORM = 13 — Variable is of type Transform.
	#TYPE_COLOR = 14 — Variable is of type Color.
	#TYPE_NODE_PATH = 15 — Variable is of type NodePath.
	#TYPE_RID = 16 — Variable is of type RID.
	#TYPE_OBJECT = 17 — Variable is of type Object.
	#TYPE_DICTIONARY = 18 — Variable is of type Dictionary.
	#TYPE_ARRAY = 19 — Variable is of type Array.
	#TYPE_RAW_ARRAY = 20 — Variable is of type PoolByteArray.
	#TYPE_INT_ARRAY = 21 — Variable is of type PoolIntArray.
	#TYPE_REAL_ARRAY = 22 — Variable is of type PoolRealArray.
	#TYPE_STRING_ARRAY = 23 — Variable is of type PoolStringArray.
	#TYPE_VECTOR2_ARRAY = 24 — Variable is of type PoolVector2Array.
	#TYPE_VECTOR3_ARRAY = 25 — Variable is of type PoolVector3Array.
	#TYPE_COLOR_ARRAY = 26 — Variable is of type PoolColorArray.
	#TYPE_MAX = 27 — Marker for end of type constants.
	
	if typeof(val) == TYPE_VECTOR2:
		val = {"__class":"Vector2", "value": var2str(val)}
	elif not typeof(val) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_REAL, TYPE_STRING, TYPE_DICTIONARY, TYPE_ARRAY]:
		print("warning: (", path,  " = ", val, ") trying to serialize an unknown type to JSON")
	
	sub[splices[-1]] = val
			

func init_cargo():
	if modified_attributes.has("cargo") or not base_attributes.has("cargo"):
		return
	
	modified_attributes["cargo"] = {}
	modified_attributes.cargo["content"] = base_attributes.cargo.content
	modified_attributes.cargo["volume_used"] = 0
	for item in modified_attributes.cargo.content:
		var item_data = Globals.LevelLoaderRef.LoadJSON(item.src)
		var vol = item_data.equipment.volume
		modified_attributes.cargo["volume_used"] += vol * item.count

func init_mounts():
	if modified_attributes.has("mounts") or not base_attributes.has("mounts"):
		return
		
	#TODO: this is just going to create a reference isn't ? Might cause issues if I start caching baseattributes
	modified_attributes["mounts"] = base_attributes.mounts

func _ready():
	if PreloadData == null or PreloadData.empty():
		return
		
	if not PreloadJSON.empty():
		modified_attributes = JSON.parse(PreloadJSON).result
	Globals.LevelLoaderRef.RequestObject(PreloadData, Globals.LevelLoaderRef.World_to_Tile(self.global_position), modified_attributes)
	self.visible = false

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
