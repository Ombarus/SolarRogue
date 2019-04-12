extends Node

# class member variables go here, for example:
export var startLevel = "data/json/levels/start.json"
export var levelSize = Vector2(80,80)
export var tileSize = 128

var cur_save = {}
var perm_save = {}
var levelTiles = []
var objCountByType = {}
var shufflingArray = []
var current_depth = 0
var objByType = {}
var objById = {}
var num_generated_level = 0
# TODO: init id when loading saved game
var _sequence_id = 0 # for giving unique name to objects
var _current_level_data = null
var _wait_for_anim = false
var _global_spawns = {} # to keep track of items that should only appear once in a single game

func GetCurrentLevelData():
	return _current_level_data
	
func GetGlobalSpawn(src):
	if not src in _global_spawns:
		return 0
	return _global_spawns[src]

func GetObjectById(id):
	if id in objById:
		return objById[id]
	else:
		return null

func GetTile(coord):
	if coord.x >= levelTiles.size() || coord.y >= levelTiles[coord.x].size():
		return []
	return levelTiles[coord.x][coord.y]

func GetLevelID():
	return str(current_depth) + _current_level_data.src
	
#func _notification(what):
#	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
#		SaveState(_current_level_data)

func _ready():
	Globals.LevelLoaderRef = self
	BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	BehaviorEvents.connect("OnRequestLevelChange", self, "OnRequestLevelChange_Callback")
	BehaviorEvents.connect("OnPlayerDeath", self, "OnPlayerDeath_Callback")
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	
	var bound_line = get_node("/root/Root/Upper-Left-Bound/L1")
	bound_line.add_point(Vector2(-tileSize/2.0, -tileSize/2.0))
	bound_line.add_point(Vector2(levelSize.x * tileSize - tileSize/2.0, -tileSize/2.0))
	bound_line.add_point(Vector2(levelSize.x * tileSize - tileSize/2.0, levelSize.y * tileSize - tileSize/2.0))
	bound_line.add_point(Vector2(-tileSize/2, levelSize.y * tileSize - tileSize/2.0))
	bound_line.add_point(Vector2(-tileSize/2, -tileSize/2))
	
	#TODO: use my own randomizer
	# Seems to be working fine. Distribution is pretty flat over huge number of throws.
	# Average is good
	# Saving and restoring state seems to work
	#MersenneTwister.set_seed(2)
	MersenneTwister.randomize_seed()
	#seed( 2 )
	
	levelTiles.clear()
	for x in range(levelSize.x):
		levelTiles.push_back([])
		for y in range(levelSize.y):
			levelTiles[x].push_back([])
			shufflingArray.push_back(Vector2(x, y))
	
	
	if File.new().file_exists("user://savegame.save"):
		cur_save = LoadJSON("user://savegame.save")
	#cur_save["depth"] = current_depth
	#cur_save["current_sequence_id"] = _sequence_id
	#cur_save["current_level_src"] = _current_level_data["src"]
	#cur_save["player_data"] = {}
	#cur_save.player_data["src"] = objByType["player"][0].get_attrib("src")
	#cur_save.player_data["position_x"] = World_to_Tile(objByType["player"][0].position).y
	#cur_save.player_data["position_y"] = World_to_Tile(objByType["player"][0].position).x
	#cur_save.player_data["modified_attributes"] = objByType["player"][0].modified_attributes
	#if not cur_save.has("modified_levels"):
	if cur_save != null and cur_save.size() > 0:
		startLevel = cur_save.current_level_src
		current_depth = cur_save.depth
		num_generated_level = cur_save.generated_levels
		_sequence_id = cur_save.current_sequence_id
		_global_spawns = cur_save.global_spawns
		Globals.total_turn = cur_save.total_turn
	
	var data = LoadJSON(startLevel)
	if data != null:
		ExecuteLoadLevel(data)
		
	
func ExecuteLoadLevel(levelData):
	#TODO: Optimize (maybe hide node and unload in a thread or 5-6 per frame)
	_UnloadLevel()
	
	var loaded = false
	if cur_save != null && cur_save.size() > 0:
		var level_id = str(current_depth) + levelData.src
		if cur_save.modified_levels.has(level_id):
			#startLevel = cur_save.current_level_src
			#current_depth = cur_save.depth
			#_sequence_id = cur_save.current_sequence_id
			GenerateLevelFromSave(levelData, cur_save.modified_levels[level_id])
			
			loaded = true
	
	if not loaded:
		GenerateLevelFromTemplate(levelData)
					
	BehaviorEvents.emit_signal("OnLevelLoaded")
	
func GenerateLevelFromSave(levelData, savedData):
	#output[key] = {}
	#output[key]["src"] = objById[key].get_attrib("src")
	#output[key]["position_x"] = World_to_Tile(objById[key].position).x
	#output[key]["position_y"] = World_to_Tile(objById[key].position).y
	#output[key]["modified_attributes"] = objById[key].modified_attributes
	_current_level_data = levelData
	var n = null
	for key in savedData:
		var data = LoadJSON(savedData[key].src)
		var coord = Vector2(savedData[key].position_x, savedData[key].position_y)
		n = CreateAndInitNode(data, coord, savedData[key].modified_attributes)
		
	
func GenerateLevelFromTemplate(levelData):
	num_generated_level += 1
	
	# exceptionaly, when on the first level the wormhole to go "back" is a wormhole to current level
	if _current_level_data == null:
		_current_level_data = levelData
	var allTilesCoord = ShuffleArray(shufflingArray)
	var i = MersenneTwister.rand(allTilesCoord.size()) # choose a random spawn point for the entrance
	# there must always be a wormhole leading back where we came from
	var depth_override = {"depth":current_depth - 1}
	var n = CreateAndInitNode(_current_level_data, allTilesCoord[i], depth_override)
	allTilesCoord.remove(i)
	_current_level_data = levelData
	
	for tileCoord in allTilesCoord:
		for obj in levelData["objects"]:
			var do_spawn = false
			if objCountByType.has(obj["name"]) && obj.has("max") && objCountByType[obj["name"]] >= obj["max"]:
				continue
			if obj.has("global_max") && obj["name"] in _global_spawns && obj["global_max"] >= _global_spawns[obj["name"]]:
				continue
			if obj.has("tile_margin") and ( \
				tileCoord[0] - obj.tile_margin[0] < 0 or \
				tileCoord[0] + obj.tile_margin[0] >= levelSize[0] or \
				tileCoord[1] - obj.tile_margin[1] < 0 or \
				tileCoord[1] + obj.tile_margin[1] >= levelSize[1]):
					continue
			if obj.has("min") && (!objCountByType.has(obj["name"]) || objCountByType[obj["name"]] < obj["min"]):
				do_spawn = true
			if !do_spawn && obj.has("spawn_rate"):
				if MersenneTwister.rand_float() < obj["spawn_rate"]:
					do_spawn = true
	
			if do_spawn:
				var data = null
				if ".json" in obj["name"]:
					data = LoadJSON(obj["name"])
				else:
					data = load(obj["name"])
				if data != null:
					if objCountByType.has(obj["name"]):
						objCountByType[obj["name"]] += 1
					else:
						objCountByType[obj["name"]] = 1
					var confirmed_coord = tileCoord
					if obj.has("pos"):
						confirmed_coord = Vector2(obj["pos"][0], obj["pos"][1])
						
					if ".json" in obj["name"]:
						n = CreateAndInitNode(data, confirmed_coord)
					else:
						var r = get_node("/root/Root/GameTiles")
						n = data.instance()
						n.position = Tile_to_World(confirmed_coord)
						r.call_deferred("add_child", n)
					break

func _GatherSaveData():
	var output = {}
	for key in objById:
		if objById[key] == null or objById[key].get_attrib("type") == "player":
			continue
		output[key] = {}
		output[key]["src"] = objById[key].get_attrib("src")
		output[key]["position_x"] = World_to_Tile(objById[key].position).x
		output[key]["position_y"] = World_to_Tile(objById[key].position).y
		# TODO: Add rotation ! (if ! 0 ?)
		output[key]["modified_attributes"] = objById[key].modified_attributes
		
	return output
	
func _UnloadLevel():
	for key in objById:
		if objById[key] != null:
			BehaviorEvents.emit_signal("OnRequestObjectUnload", objById[key])
		
	objById.clear()
	objCountByType.clear()

func SaveState(level_data):
	var data_to_save = _GatherSaveData()
	cur_save["depth"] = current_depth
	cur_save["current_sequence_id"] = _sequence_id
	cur_save["current_level_src"] = _current_level_data["src"]
	cur_save["generated_levels"] = num_generated_level
	cur_save["player_data"] = {}
	cur_save["global_spawns"] = _global_spawns
	cur_save["total_turn"] = Globals.total_turn
	cur_save.player_data["src"] = objByType["player"][0].get_attrib("src")
	cur_save.player_data["position_x"] = World_to_Tile(objByType["player"][0].position).x
	cur_save.player_data["position_y"] = World_to_Tile(objByType["player"][0].position).y
	cur_save.player_data["modified_attributes"] = objByType["player"][0].modified_attributes
	var level_id = str(current_depth) + _current_level_data["src"]
	if not cur_save.has("modified_levels"):
		cur_save["modified_levels"] = {}
	cur_save.modified_levels[level_id] = data_to_save
	#TODO: Add versionning
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	save_game.store_line(to_json(cur_save))
	save_game.close()

func OnTransferPlayer_Callback(old_player, new_player):
	objByType[old_player.get_attrib("type")].erase(old_player)
	old_player.set_attrib("type", "ship")
	objByType["ship"].push_back(old_player)
	objByType[new_player.get_attrib("type")].erase(new_player)
	objByType["player"].push_back(new_player)
	new_player.set_attrib("type", "player")

func OnWaitForAnimation_Callback():
	_wait_for_anim = true
	
func OnAnimationDone_Callback():
	_wait_for_anim = false

func OnRequestLevelChange_Callback(wormhole):
	SaveState(_current_level_data)
	# should be defferred !
	current_depth = wormhole.modified_attributes["depth"]
	ExecuteLoadLevel(wormhole.base_attributes)

func OnRequestObjectUnload_Callback(obj):
	var coord = World_to_Tile(obj.position)
	var content = levelTiles[coord.x][coord.y]
	content.erase(obj)
	#TODO: Proper Counting, Type in this case is the json filename which I'm not sure I have access here
	# For now only used at level init so it should be fine to leave it alone
	#objCountByType[obj.base_attributes.src] -= 1
	#TODO: Should I clean ObjById ? I might iterate through it to delete objects so removing them while I iterate is dangerous
	objById[obj.get_attrib("unique_id")] = null
	objByType[obj.get_attrib("type")].erase(obj)
	if _wait_for_anim == true:
		yield(BehaviorEvents, "OnAnimationDone")
	obj.get_parent().remove_child(obj)
	obj.queue_free()
	
func OnPlayerDeath_Callback():
	var save_game = Directory.new()
	save_game.remove("user://savegame.save")
	# Maybe this should not be in a Global eh ?
	Globals.total_turn = 0
	Globals.last_delta_turn = 0
	#var data = LoadJSON(startLevel)
	#if data != null:
	#	call_deferred("ExecuteLoadLevel", data)
	
	
func LoadJSON(filepath):
	var file = File.new()
	if not "res://" in filepath and not "user://" in filepath:
		filepath = "res://" + filepath
	file.open(filepath, file.READ)
	var text = file.get_as_text()
	var result_json = JSON.parse(text)
	file.close()
	
	var data = null
	if result_json.error == OK:  # If parse OK
		data = result_json.result
	else:  # If parse has errors
		print("Error in ", filepath)
		print("Error: ", result_json.error)
		print("Error Line: ", result_json.error_line)
		print("Error String: ", result_json.error_string)
		
	data["src"] = filepath
	return data
	
func LoadJSONArray(filepaths):
	var res = []
	if filepaths == null:
		return res
	for filepath in filepaths:
		if not filepath.empty():
			res.push_back(LoadJSON(filepath))
	return res
	
func ShuffleArray(ar):
	var shuffledList = []
	var indexList = range(ar.size())
	for i in range(ar.size()):
		#(randf() * (y-x)) + x
		var x = MersenneTwister.rand(indexList.size())
		shuffledList.append(ar[indexList[x]])
		indexList.remove(x)
	return shuffledList

func GetTileData(xy):
	return levelTiles[xy.x][xy.y]
	
func World_to_Tile(xy):
	var res = Vector2(0.0, 0.0)
	if typeof(xy) == TYPE_VECTOR2:
		res = Vector2(int(round(xy.x / tileSize)), int(round(xy.y / tileSize)))
	else:
		res = int(xy / tileSize)
	
	res.x = clamp(res.x, 0, levelSize.x-1)
	res.y = clamp(res.y, 0, levelSize.y-1)
	return res
	
func Tile_to_World(xy):
	if typeof(xy) == TYPE_VECTOR2:
		return Vector2(xy.x * tileSize, xy.y * tileSize)
	else:
		return xy * tileSize
	
func RequestObject(path, pos, modified_data = null):
	var data = LoadJSON(path)
	return CreateAndInitNode(data, pos, modified_data)


#######################################################
# EVERY OBJECT SHOULD BE CREATED THROUGH HERE
#######################################################

func CreateAndInitNode(data, pos, modified_data = null):
	var r = get_node("/root/Root/GameTiles")
	var scene = Preloader.BaseObject
	var n = scene.instance()
	if data.has("name_id"):
		var last = data["name_id"].split("/")
		n.set_name(last[-1])
	n.position = Tile_to_World(pos)
	n.base_attributes = data
	n.modified_attributes = {}
	if modified_data != null:
		n.modified_attributes = modified_data
	r.call_deferred("add_child", n)
	levelTiles[ pos.x ][ pos.y ].push_back(n)
	var obj_type = n.get_attrib("type")
	if obj_type != null:
		if not objByType.has(obj_type):
			objByType[ obj_type ] = []
		objByType[ obj_type ].push_back(n)
		if obj_type == "wormhole" and not n.modified_attributes.has("depth"):
			n.modified_attributes["depth"] = current_depth + 1
	if not n.modified_attributes.has("unique_id"):
		n.modified_attributes["unique_id"] = _sequence_id
		_sequence_id += 1
	objById[n.modified_attributes["unique_id"]] = n
	BehaviorEvents.emit_signal("OnObjectLoaded", n)
	if modified_data == null: # only count new stuff
		if not data["src"] in _global_spawns:
			_global_spawns[data["src"]] = 0
		_global_spawns[data["src"]] += 1
	return n
	
#######################################################
#######################################################
	
func UpdatePosition(obj, newPos):	
	var old_tile = World_to_Tile(obj.position)
	var new_tile = World_to_Tile(newPos)
	
	var content = levelTiles[old_tile.x][old_tile.y]
	content.erase(obj)
	levelTiles[new_tile.x][new_tile.y].push_back(obj)
	
	obj.position = newPos
	BehaviorEvents.emit_signal("OnPositionUpdated", obj)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
