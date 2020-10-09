extends Node

# class member variables go here, for example:
export var startLevel = "data/json/levels/start.json"
export var levelSize = Vector2(80,80)
export var tileSize = 128
export(NodePath) var LoadingNode : NodePath
export(NodePath) var SaveManager : NodePath = "../LocalSave"

onready var _loading : Node2D = get_node(LoadingNode)
onready var _save_manager : Node = get_node(SaveManager)

var _save
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

const _TEST_MID_GAME = false

func GetRandomEmptyTile():
	#TODO: Check for blocking and multi-tile objects
	var indexList = range(shufflingArray.size())
	var index = 0
	while indexList.size() > 0:
		index = MersenneTwister.rand(indexList.size())
		var coord = shufflingArray[indexList[index]]
		if GetTile(coord).empty():
			return coord
		indexList.remove(index)
	# should only happen if the whole level is filled with stuff. Unlikely, but just in case
	print("WOW. I couldn't find a random empty tile so I'm picking up the upper-left corner by default!!!!")
	return shufflingArray[0]

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
	if _TEST_MID_GAME == true:
		#startLevel = "data/json/levels/jerg_branch/branch06.json"
		#startLevel = "data/json/levels/human_branch/branch04.json"
		current_depth = 1
	Globals.LevelLoaderRef = self
	BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	BehaviorEvents.connect("OnRequestLevelChange", self, "OnRequestLevelChange_Callback")
	BehaviorEvents.connect("OnPlayerDeath", self, "OnPlayerDeath_Callback")
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	
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
	
	
	cur_save = _save_manager.get_latest_save()
	
	#cur_save["depth"] = current_depth
	#cur_save["current_sequence_id"] = _sequence_id
	#cur_save["current_level_src"] = _current_level_data["src"]
	#cur_save["player_data"] = {}
	#cur_save.player_data["src"] = objByType["player"][0].get_attrib("src")
	#cur_save.player_data["position_x"] = World_to_Tile(objByType["player"][0].position).y
	#cur_save.player_data["position_y"] = World_to_Tile(objByType["player"][0].position).x
	#cur_save.player_data["modified_attributes"] = objByType["player"][0].modified_attributes
	#if not cur_save.has("modified_levels"):
	
	Globals.total_turn = 0
	Globals.last_delta_turn = 0
	
	if cur_save != null and cur_save.size() > 0:
		startLevel = cur_save.current_level_src
		current_depth = cur_save.depth
		num_generated_level = cur_save.generated_levels
		_sequence_id = cur_save.current_sequence_id
		_global_spawns = cur_save.global_spawns
		Globals.total_turn = cur_save.total_turn
	
	var data = LoadJSON(startLevel)
	if data != null:
		set_loading(true)
		yield(ExecuteLoadLevel(data), "completed")
		set_loading(false)
		
func _exit_tree():
	Globals.LevelLoaderRef = null
	
func ExecuteLoadLevel(levelData):
	yield(_UnloadLevel(), "completed")
	
	BehaviorEvents.emit_signal("OnStartLoadLevel")
	
	var loaded = false
	if cur_save != null && cur_save.size() > 0:
		var level_id = str(current_depth) + levelData.src
		if cur_save.modified_levels.has(level_id):
			#startLevel = cur_save.current_level_src
			#current_depth = cur_save.depth
			#_sequence_id = cur_save.current_sequence_id
			yield(GenerateLevelFromSave(levelData, cur_save.modified_levels[level_id]), "completed")
			
			loaded = true
	
	if not loaded:
		yield(GenerateLevelFromTemplate(levelData), "completed")
					
	BehaviorEvents.emit_signal("OnLevelLoaded")
	
	
func GenerateLevelFromSave(levelData, savedData):
	yield(get_tree(), "idle_frame")
	#output[key] = {}
	#output[key]["src"] = objById[key].get_attrib("src")
	#output[key]["position_x"] = World_to_Tile(objById[key].position).x
	#output[key]["position_y"] = World_to_Tile(objById[key].position).y
	#output[key]["modified_attributes"] = objById[key].modified_attributes
	_current_level_data = levelData
	var n = null
	var start_time : int = OS.get_ticks_msec()
	var cur_time : int = start_time
	for key in savedData:
		var data = LoadJSON(savedData[key].src)
		var coord = Vector2(savedData[key].position_x, savedData[key].position_y)
		n = CreateAndInitNode(data, coord, savedData[key].modified_attributes)
		if "rotation" in savedData[key]:
			n.rotation = savedData[key].rotation
		
		cur_time = OS.get_ticks_msec()
		if cur_time - start_time > 33:
			start_time = cur_time
			yield(get_tree(), "idle_frame")
		
	
func GenerateLevelFromTemplate(levelData):
	yield(get_tree(), "idle_frame")
	var start_time : int = OS.get_ticks_msec()
	var cur_time : int = start_time
	var blocked_tiles : Dictionary = {}
	
	num_generated_level += 1
	# exceptionaly, when on the first level the wormhole to go "back" is a wormhole to current level
	if _current_level_data == null:
		_current_level_data = levelData
	var allTilesCoord = ShuffleArray(shufflingArray)
	var levelDataObj = levelData["objects"]
	
	# Try to spawn object with a hardcoded position (like the sun)
	# they have priority over randomly positionned stuff
	for obj in levelDataObj:
		var do_spawn = false
		if objCountByType.has(obj["name"]) && obj.has("max") && objCountByType[obj["name"]] >= obj["max"]:
				continue
		if obj.has("global_max") && Globals.clean_path(obj["name"]) in _global_spawns && obj["global_max"] >= _global_spawns[Globals.clean_path(obj["name"])]:
			continue
		if obj.has("pos"):
			if obj.has("min") && (!objCountByType.has(obj["name"]) || objCountByType[obj["name"]] < obj["min"]):
				do_spawn = true
			if !do_spawn && obj.has("spawn_rate"):
				if MersenneTwister.rand_float() < obj["spawn_rate"]:
					do_spawn = true
		if do_spawn:
			_do_spawn(obj, Vector2(obj["pos"][0], obj["pos"][1]), blocked_tiles)
	
	var i := 0
	
	#var i = MersenneTwister.rand(allTilesCoord.size()) # choose a random spawn point for the entrance
	# there must always be a wormhole leading back where we came from
	var depth_override = {"depth":current_depth - 1}
	# make sure we don't take the spot of the sun or something else with a hardcoded position
	while i < allTilesCoord.size():
		if not allTilesCoord[i] in blocked_tiles:
			break # Ok spawn point, stop looking
		i += 1
	var spawn_point = allTilesCoord[i]
	#print("Spawn Point " + str(spawn_point))
	
	# HACK: current_level doesn't appear in the list of level object 
	# so I hardcoded it's margin based on my knowledge of the sprite wormhole
	# (3x3)
	for x in range(3):
		for y in range(3):
			var blocked = spawn_point + Vector2(x - 1, y - 1)
			blocked_tiles[blocked] = true
	
	var n = CreateAndInitNode(_current_level_data, spawn_point, depth_override)
	allTilesCoord.remove(i)
	_current_level_data = levelData
	
	var cur_tile_index := 0
	for tileCoord in allTilesCoord:
		cur_tile_index += 1
		cur_time = OS.get_ticks_msec()
		if cur_time - start_time > 200:
			#BehaviorEvents.emit_signal("OnLogLine", "Loading : " + str(cur_tile_index) + " / " + str(allTilesCoord.size()))
			yield(get_tree(), "idle_frame")
			start_time = cur_time
		
		for obj in levelDataObj:
			var do_spawn = false
			if objCountByType.has(obj["name"]) && obj.has("max") && objCountByType[obj["name"]] >= obj["max"]:
				continue
			if obj.has("global_max") && Globals.clean_path(obj["name"]) in _global_spawns && obj["global_max"] >= _global_spawns[Globals.clean_path(obj["name"])]:
				continue
			if obj.has("tile_margin") and ( \
				tileCoord[0] - obj.tile_margin[0] < 0 or \
				tileCoord[0] + obj.tile_margin[0] >= levelSize[0] or \
				tileCoord[1] - obj.tile_margin[1] < 0 or \
				tileCoord[1] + obj.tile_margin[1] >= levelSize[1]):
					continue
			if obj.has("pos"): # already handled above
				continue
			if tileCoord in blocked_tiles:
				continue
			if "sprite_margin" in obj:
				var is_blocked := false
				for x in range((obj["sprite_margin"][0]*2)+1):
					for y in range((obj["sprite_margin"][1]*2)+1):
						var blocked = tileCoord + Vector2(x - obj["sprite_margin"][0], y - obj["sprite_margin"][1])
						if blocked in blocked_tiles:
							is_blocked = true
				if is_blocked == true:
					continue
			if obj.has("min") && (!objCountByType.has(obj["name"]) || objCountByType[obj["name"]] < obj["min"]):
				do_spawn = true
			if !do_spawn && obj.has("spawn_rate"):
				if MersenneTwister.rand_float() < obj["spawn_rate"]:
					do_spawn = true
					
			if do_spawn:
				_do_spawn(obj, tileCoord, blocked_tiles)
				break
					
func _do_spawn(obj, tileCoord, blocked_tiles):
	var data = null
	var n = null
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
		
		blocked_tiles[confirmed_coord] = true
		if "sprite_margin" in obj:
			for x in range((obj["sprite_margin"][0]*2)+1):
				for y in range((obj["sprite_margin"][1]*2)+1):
					var blocked = confirmed_coord + Vector2(x - obj["sprite_margin"][0], y - obj["sprite_margin"][1])
					blocked_tiles[blocked] = true
		
		if ".json" in obj["name"]:
			n = CreateAndInitNode(data, confirmed_coord)
		else:
			var r = get_node("/root/Root/GameTiles")
			n = data.instance()
			n.position = Tile_to_World(confirmed_coord)
			r.call_deferred("add_child", n)

func _GatherSaveData():
	yield(get_tree(), "idle_frame")
	var start_time : int = OS.get_ticks_msec()
	var cur_time : int = start_time
	var output = {}
	var one_obj = null
	for key in objById:
		one_obj = objById[key]
		if one_obj == null or one_obj.get_attrib("type") == "player":
			continue
		output[key] = {}
		output[key]["src"] = one_obj.get_attrib("src")
		var tile = World_to_Tile(one_obj.position)
		
		# One hell of a hack. Because AIs can move in parallel, we might end up trying to save
		# while a ship is moving. It's fine but we need to make 100% sure we save the right tile
		# and right now there's no guaranty that the ship is on the right tile if it's animating, so
		# Normally I would do "wait for animation" but I don't want to delay the saving.
		# the only solution I can think of is to look for it. It can't be more than 1 tile away from 
		# it's destination
		if one_obj.get_attrib("animation.in_movement") == true:
			var found := false
			for offset_x in range(-1, 2):
				for offset_y in range(-1, 2):
					var content : Array = GetTile(Vector2(tile.x + offset_x,tile.y + offset_y))
					if one_obj in content:
						tile = Vector2(tile.x + offset_x,tile.y + offset_y)
						found = true
						break
				if found == true:
					break
			
		#############################################################################################
			
		output[key]["position_x"] = tile.x
		output[key]["position_y"] = tile.y
		if one_obj.rotation != 0.0:
			output[key]["rotation"] = one_obj.rotation
		output[key]["modified_attributes"] = one_obj.modified_attributes
		
		cur_time = OS.get_ticks_msec()
		if cur_time - start_time > 33:
			start_time = cur_time
			yield(get_tree(), "idle_frame")
		
	return output
	
func _UnloadLevel():
	yield(get_tree(), "idle_frame")
	var start_time : int = OS.get_ticks_msec()
	var cur_time : int = start_time
	for key in objById:
		if objById[key] != null:
			BehaviorEvents.emit_signal("OnRequestObjectUnload", objById[key])
		
		cur_time = OS.get_ticks_msec()
		if cur_time - start_time > 33:
			start_time = cur_time
			yield(get_tree(), "idle_frame")
		
	objById.clear()
	objCountByType.clear()

func SaveStateAndQuit(level_data):
	if objByType["player"][0].get_attrib("destroyable.destroyed", false) == true:
		if Globals.is_ios():
			get_tree().change_scene("res://scenes/MainMenu.tscn")
		else:
			get_tree().quit()
		return
			
	var data_to_save : Dictionary = yield(_GatherSaveData(), "completed")
	cur_save["timestamp"] = OS.get_unix_time()
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
	cur_save.player_data["rotation"] = objByType["player"][0].rotation
	cur_save.player_data["modified_attributes"] = objByType["player"][0].modified_attributes
	var level_id = str(current_depth) + _current_level_data["src"]
	if not cur_save.has("modified_levels"):
		cur_save["modified_levels"] = {}
	cur_save.modified_levels[level_id] = data_to_save
	#TODO: Add versionning
	_save_manager.save_and_quit(cur_save)
	

func SaveState(level_data):
	yield(get_tree(), "idle_frame") # https://github.com/godotengine/godot/pull/34280
	if _save_manager.is_saving() or objByType["player"][0].get_attrib("destroyable.destroyed", false) == true:
		return
	var data_to_save : Dictionary = yield(_GatherSaveData(), "completed")
	cur_save["timestamp"] = OS.get_unix_time()
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
	cur_save.player_data["rotation"] = objByType["player"][0].rotation
	cur_save.player_data["modified_attributes"] = objByType["player"][0].modified_attributes
	var level_id = str(current_depth) + _current_level_data["src"]
	if not cur_save.has("modified_levels"):
		cur_save["modified_levels"] = {}
	cur_save.modified_levels[level_id] = data_to_save
	#TODO: Add versionning
	_save_manager.start_save(cur_save)
	#_save_thread.start(self, "save_thread", cur_save)


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
	set_loading(true)
	yield(SaveState(_current_level_data), "completed")
	# should be defferred !
	current_depth = wormhole.modified_attributes["depth"]
	yield(ExecuteLoadLevel(wormhole.base_attributes), "completed")
	BehaviorEvents.call_deferred("emit_signal", "OnLevelReady")
	set_loading(false)

func OnRequestObjectUnload_Callback(obj):
	var coord = World_to_Tile(obj.position)
	var content = levelTiles[coord.x][coord.y]
	if content.find(obj) == -1:
		print("COULD NOT FIND " + str(obj) + " AT TILE (" + str(coord.x) + ", " + str(coord.y) + "), obj is at world (" + str(obj.position) + ")")

	content.erase(obj)
	
	#TODO: Proper Counting, Type in this case is the json filename which I'm not sure I have access here
	# For now only used at level init so it should be fine to leave it alone
	#objCountByType[obj.base_attributes.src] -= 1
	#TODO: Should I clean ObjById ? I might iterate through it to delete objects so removing them while I iterate is dangerous
	objById[obj.get_attrib("unique_id")] = null
	objByType[obj.get_attrib("type")].erase(obj)
	
	# will be executed immediately if there's no animation, or will wait till all animations are done
	BehaviorEvents.emit_signal("OnAddToAnimationQueue", self, "_do_remove", [obj], 550)
	#if _wait_for_anim == true:
	#	yield(BehaviorEvents, "OnAnimationDone")
	#obj.get_parent().remove_child(obj)
	#obj.queue_free()
	
func _do_remove(obj):
	obj.get_parent().remove_child(obj)
	obj.queue_free()
	
func OnPlayerDeath_Callback(player):
	_save_manager.delete_save()
	# Maybe this should not be in a Global eh ?
	#var data = LoadJSON(startLevel)
	#if data != null:
	#	call_deferred("ExecuteLoadLevel", data)
	
	
func LoadJSON(filepath):
	var file = File.new()
	if not "res://" in filepath and not "user://" in filepath:
		filepath = "res://" + filepath
	
	if filepath in Preloader.JsonCache:
		return Preloader.JsonCache[filepath]
	
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
	
	if data != null:
		data["src"] = filepath
		Preloader.JsonCache[filepath] = data
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
	#print("ShuffleArray : " + str(shuffledList))
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
		# If I init objects with modified data in a loop and pass the same dictionnary
		# it'll be shared between multiple objects. To avoid this, make sure I save a copy
		# (see dropping food in ProcessHarvest())
		n.modified_attributes = str2var(var2str(modified_data))
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
	if n.get_attrib("animation.in_movement") == true:
		n.set_attrib("animation.in_movement", false)
	BehaviorEvents.emit_signal("OnObjectLoaded", n)
	if modified_data == null: # only count new stuff
		var clean_path = Globals.clean_path(data["src"])
		if not clean_path in _global_spawns:
			_global_spawns[clean_path] = 0
		_global_spawns[clean_path] += 1
	return n
	
#######################################################
#######################################################
	
func UpdatePosition(obj, newPos, teleport=false):	
	var old_tile = World_to_Tile(obj.position)
	var new_tile = World_to_Tile(newPos)
	if old_tile == new_tile:
		return
	
	var content = levelTiles[old_tile.x][old_tile.y]
	content.erase(obj)
	levelTiles[new_tile.x][new_tile.y].push_back(obj)
	
	var has_movement_anim : bool = obj.find_node("MovementAnimations", true, false) != null
	# ghost are not moved with animation because they teleport when scanner update
	has_movement_anim = has_movement_anim and obj.get_attrib("ghost_memory") == null
	#print("%s : %s" % [obj.name, obj.visible])
	if not has_movement_anim or teleport == true or obj.visible == false:
		obj.position = newPos
		BehaviorEvents.emit_signal("OnPositionUpdated", obj)

func set_loading(var is_loading : bool):
	if is_loading == true:
		BehaviorEvents.emit_signal("OnHideGUI", "HUD") # HUD
		get_node("../AP").OnWaitForAnimation_Callback()
	if is_loading == false:
		BehaviorEvents.emit_signal("OnShowGUI", "HUD", null, "popin")
		get_node("../AP").OnAnimationDone_Callback()
	
	if _loading == null:
		return	
	get_node("../../BG").visible = !is_loading
	get_node("../../GameTiles").visible = !is_loading
	get_node("../../base_green").visible = !is_loading
	#get_node("../../Camera-GUI/SafeArea/HUD_root").visible = !is_loading
	get_node("../../BorderTiles").visible = !is_loading
	ShortcutManager.Enabled = !is_loading
	
	if is_loading == false:
		_loading.get_node("AnimationPlayer").play("popout")
	else:
		_loading.visible = is_loading
