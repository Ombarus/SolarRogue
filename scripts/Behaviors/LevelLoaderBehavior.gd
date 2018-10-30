extends Node

# class member variables go here, for example:
export var startLevel = "data/json/levels/start.json"
export var levelSize = Vector2(80,80)
export var tileSize = 128

var levelTiles = []
var objCountByType = {}
var shufflingArray = []
var current_depth = 0
var objByType = {}


func _ready():
	var bound_line = get_node("/root/Root/Upper-Left-Bound/L1")
	bound_line.add_point(Vector2(-tileSize/2, -tileSize/2))
	bound_line.add_point(Vector2(levelSize.x * tileSize, -tileSize/2))
	bound_line.add_point(Vector2(levelSize.x * tileSize, levelSize.y * tileSize))
	bound_line.add_point(Vector2(-tileSize/2, levelSize.y * tileSize))
	bound_line.add_point(Vector2(-tileSize/2, -tileSize/2))
	
	#TODO: use my own randomizer
	#randomize()
	seed( 2 )
	
	levelTiles.clear()
	for x in range(levelSize.x):
		levelTiles.push_back([])
		for y in range(levelSize.y):
			levelTiles[x].push_back([])
			shufflingArray.push_back(Vector2(x, y))
	
	var data = LoadJSON(startLevel)
	if data != null:
		ExecuteLoadLevel(data)
		
	
func ExecuteLoadLevel(levelData):
	# TODO: Unload previous level
	
	var allTilesCoord = ShuffleArray(shufflingArray)
	var i = int(randf() * allTilesCoord.size()) # choose a random spawn point for the entrance
	var n = CreateAndInitNode(levelData, allTilesCoord[i])
	n.modified_attributes["depth"] = current_depth - 1
	allTilesCoord.remove(i)
	
	for tileCoord in allTilesCoord:
		for obj in levelData["objects"]:
			var do_spawn = false
			if objCountByType.has(obj["name"]) && obj.has("max") && objCountByType[obj["name"]] >= obj["max"]:
				continue
			if obj.has("min") && (!objCountByType.has(obj["name"]) || objCountByType[obj["name"]] < obj["min"]):
				do_spawn = true
			if !do_spawn && obj.has("spawn_rate"):
				if randf() < obj["spawn_rate"]:
					do_spawn = true
	
			if do_spawn:	
				var data = LoadJSON(obj["name"])
				if data != null:
					if objCountByType.has(obj["name"]):
						objCountByType[obj["name"]] += 1
					else:
						objCountByType[obj["name"]] = 1
					var confirmed_coord = tileCoord
					if obj.has("pos"):
						confirmed_coord = Vector2(obj["pos"][0], obj["pos"][1])
						
					n = CreateAndInitNode(data, confirmed_coord)
					break
					
	BehaviorEvents.emit_signal("OnLevelLoaded")
	
	
func LoadJSON(filepath):
	var file = File.new()
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
		
	return data
	
func ShuffleArray(ar):
	var shuffledList = []
	var indexList = range(ar.size())
	for i in range(ar.size()):
		#(randf() * (y-x)) + x
		var x = int(randf() * indexList.size())
		shuffledList.append(ar[indexList[x]])
		indexList.remove(x)
	return shuffledList

func GetTileData(xy):
	return levelTiles[xy.x][xy.y]
	
func World_to_Tile(xy):
	if typeof(xy) == TYPE_OBJECT:
		return Vector2(int(xy.x / tileSize), int(xy.y / tileSize))
	else:
		return xy / tileSize
	
func Tile_to_World(xy):
	if typeof(xy) == TYPE_OBJECT:
		return Vector2(int(xy.x * tileSize), int(xy.y * tileSize))
	else:
		return xy * tileSize
	
func RequestObject(path, pos):
	var data = LoadJSON(path)
	return CreateAndInitNode(data, pos)
	
func CreateAndInitNode(data, pos):
	var r = get_node("/root/Root/GameTiles")
	var scene = load("res://scenes/object.tscn")
	var n = scene.instance()
	if data.has("name_id"):
		var last = data["name_id"].split("/")
		n.set_name(last[-1])
	n.position = Tile_to_World(pos)
	n.base_attributes = data
	r.call_deferred("add_child", n)
	levelTiles[ pos.x ][ pos.y ].push_back(n)
	if data.has("type"):
		if not objByType.has(data["type"]):
			objByType[ data["type"] ] = []
		objByType[ data["type"] ].push_back(n)
		if data["type"] == "wormhole":
			n.modified_attributes["depth"] = current_depth + 1
	BehaviorEvents.emit_signal("OnObjectLoaded", n)
	return n
	
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
