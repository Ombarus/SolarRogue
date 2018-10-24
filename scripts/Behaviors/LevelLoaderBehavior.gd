extends Node

# class member variables go here, for example:
export var startLevel = "data/json/levels/start.json"
export var levelSize = Vector2(80,80)

var levelTiles = []
var objCountByType = {}
var shufflingArray = []
signal OnObjectLoaded(obj, pos)

func _ready():
	#TODO use my own randomizer
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
	emit_signal("OnObjectLoaded", levelData, allTilesCoord[i])
	levelTiles[ allTilesCoord[i].x ][ allTilesCoord[i].y ].push_back(levelData)
	allTilesCoord.remove(i)
	
	for tileCoord in allTilesCoord:
		for obj in levelData["objects"]:
			var do_spawn = false
			if objCountByType.has(obj["name"]) && obj.has("max") && objCountByType[obj["name"]] > obj["max"]:
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
					levelTiles[ confirmed_coord.x ][ confirmed_coord.y ].push_back(levelData)
					emit_signal("OnObjectLoaded", data, confirmed_coord)
					break
	
	
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

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
