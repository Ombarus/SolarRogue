extends Node

var _playerNode = null
var last_known_player_pos = null

func _ready():
	BehaviorEvents.connect("OnPositionUpdated", self, "OnPositionUpdated_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")

func OnObjectLoaded_Callback(obj):
	if obj.get_attrib("type") == "player":
		_playerNode = obj
		last_known_player_pos = Globals.LevelLoaderRef.World_to_Tile(_playerNode.position)
		BehaviorEvents.disconnect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
		BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
		
		#debug
		#var player_scanner_data = _GetPlayerScannerData()
		#var scan_radius = player_scanner_data.scanning.radius
		#var scan_radius_sq = scan_radius*scan_radius
		
		#var temp_template = "res://data/json/items/misc/hydrogen.json"
		#var n = null
		#var offset = Vector2(0,0)
		#while round(offset.length()) <= scan_radius:
		#	while round(offset.length()) <= scan_radius:
		#		print("offset (",offset, "), length = ", offset.length())
		#		#expending in positive x & y then checking the other 3 cadran
		#		#           |
		#		#        d  |  a
		#		#--------------------------
		#		#        c  |  b
		#		#           |
		#		#           |
		#		n = Globals.LevelLoaderRef.RequestObject(temp_template, last_known_player_pos + offset)
		#		offset.x *= -1
		#		n = Globals.LevelLoaderRef.RequestObject(temp_template, last_known_player_pos + offset)
		#		offset.y *= -1
		#		n = Globals.LevelLoaderRef.RequestObject(temp_template, last_known_player_pos + offset)
		#		offset.x *= -1
		#		n = Globals.LevelLoaderRef.RequestObject(temp_template, last_known_player_pos + offset)
		#		offset.y *= -1
		#		offset.y += 1
		#	offset.y = 0
		#	offset.x += 1
	
func OnRequestObjectUnload_Callback(obj):
	if obj == _playerNode:
		_playerNode = null
		BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
		BehaviorEvents.disconnect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	
func OnPositionUpdated_Callback(obj):
	var player_scanner_data = _GetPlayerScannerData()
	
	var scan_radius = player_scanner_data.scanning.radius
	var scan_radius_sq = scan_radius*scan_radius
	if obj != _playerNode:
		# Have to check if obj went out of sight
		var obj_tile = Globals.LevelLoaderRef.World_to_Tile(obj.position)
		var player_tile = Globals.LevelLoaderRef.World_to_Tile(_playerNode.position)
		if (obj_tile - player_tile).length_squared() > scan_radius_sq and (obj_tile - last_known_player_pos).length_squared() <= scan_radius_sq:
			#TODO: Add to memory
			pass
		
		if (obj_tile - player_tile).length_squared() > scan_radius_sq:
			obj.visible = false
		else:
			obj.visible = true
	else:
		# Have to check tiles adjencent to player
		_updateAdjascentTile(scan_radius)
		#TODO: tag seen tiles
		last_known_player_pos = Globals.LevelLoaderRef.World_to_Tile(_playerNode.position)
	
func _updateAdjascentTile(scan_radius):
	var offset = Vector2(0,0)
	while round(offset.length()) <= (scan_radius+1):
		while round(offset.length()) <= (scan_radius+1):
			#expanding in positive x & y then checking the other 3 quadrant
			#           |
			#        d  |  a
			#--------------------------
			#        c  |  b
			#           |
			#           |
			var tile = last_known_player_pos + offset
			var obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
			for o in obj_in_tile:
				_UpdateMemory(o, scan_radius)
			offset.x *= -1
			tile = last_known_player_pos + offset
			obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
			for o in obj_in_tile:
				_UpdateMemory(o, scan_radius)
			offset.y *= -1
			tile = last_known_player_pos + offset
			obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
			for o in obj_in_tile:
				_UpdateMemory(o, scan_radius)
			offset.x *= -1
			tile = last_known_player_pos + offset
			obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
			for o in obj_in_tile:
				_UpdateMemory(o, scan_radius)
			offset.y *= -1
			offset.y += 1
		offset.y = 0
		offset.x += 1
	
func _UpdateMemory(obj, scan_radius):
	var obj_tile = Globals.LevelLoaderRef.World_to_Tile(obj.position)
	var player_tile = Globals.LevelLoaderRef.World_to_Tile(_playerNode.position)
	if round((obj_tile - player_tile).length()) > scan_radius and round((obj_tile - last_known_player_pos).length()) <= scan_radius:
		var data = {"position":var2str(obj_tile), "sprite":obj.get_attrib("sprite")}
		var path = "memory.objects." + str(obj.get_attrib("unique_id"))
		_playerNode.set_attrib(path, data)
	
	if round((obj_tile - player_tile).length()) > scan_radius:
		obj.visible = false
		#TODO: need to remove unique_id from obj.modified_attributes
		#TODO: need to generate "memory" modified_attributes component (with 0~1 saturation value & reference unique_id)
		# no better way to deep copy a dictionary I think
		#var modified_copy = JSON.parse(to_json(obj.modified_attributes))
		#Globals.LevelLoaderRef.RequestObject(obj.get_attrib("src"), obj_tile, obj.modified_attributes)
	else:
		obj.visible = true
	
func _GetPlayerScannerData():
	#TODO: OMG, cache that or I'm going to have to hide in shame !
	var player_scanner_json = _playerNode.get_attrib("mounts.scanner")
	var player_scanner_data = null
	if player_scanner_json != null and player_scanner_json != "":
		player_scanner_data = Globals.LevelLoaderRef.LoadJSON(player_scanner_json)
	return player_scanner_data

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
