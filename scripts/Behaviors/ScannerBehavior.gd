extends Node

var _node_id_scanner = {}
var _up_to_date = false

func _ready():
	BehaviorEvents.connect("OnPositionUpdated", self, "OnPositionUpdated_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	
func OnMountAdded_Callback(obj, slot, src):
	if not "scanner" in slot:
		return
		
	var scanner_data = null
	if src != null and src != "":
		scanner_data = Globals.LevelLoaderRef.LoadJSON(src)
		_node_id_scanner[obj.get_attrib("unique_id")] = scanner_data
		_up_to_date = false
	
	special_update_ultimate(obj, scanner_data)
	
func OnMountRemoved_Callback(obj, slot, src):
	if not "scanner" in slot:
		return
		
	_node_id_scanner.erase(obj.get_attrib("unique_id"))
	_up_to_date = false
	
func OnLevelLoaded_Callback():
	_up_to_date = false

func OnPositionUpdated_Callback(obj):
	#TODO: this might get expensive. Maybe do some culling before doing a full update
	_up_to_date = false
	
func OnObjectLoaded_Callback(obj):
	var scanners = obj.get_attrib("mounts.scanner")
	if scanners == null or scanners.size() <= 0:
		return
	
	var scanner_name = scanners[0]
	if scanner_name != null and scanner_name != "":
		var scanner_data = Globals.LevelLoaderRef.LoadJSON(scanner_name)
		_node_id_scanner[obj.get_attrib("unique_id")] = scanner_data
		special_update_ultimate(obj, scanner_data)
	
func OnRequestObjectUnload_Callback(obj):
	_node_id_scanner.erase(obj.get_attrib("unique_id"))
	
func special_update_ultimate(obj, scanner_data):
	if scanner_data != null and Globals.is_(Globals.get_data(scanner_data, "scanning.fully_mapped"), true):
		var level_id : String = Globals.LevelLoaderRef.GetLevelID()
		var old_range : Array = obj.get_attrib("scanner_result.cur_in_range." + level_id)
		var cur_in_range := []
		for key in Globals.LevelLoaderRef.objById:
			var o : Node2D = Globals.LevelLoaderRef.objById[key]
			# Removed objects just get set to null so we might have null obj in objById
			if o != null:
				cur_in_range.push_back(o.get_attrib("unique_id"))
			
		obj.set_attrib("scanner_result.cur_in_range." + level_id, cur_in_range)
	
func _process(delta):
	if _up_to_date == true:
		return
		
	_up_to_date = true
		
	for id in _node_id_scanner:
		var obj = Globals.LevelLoaderRef.GetObjectById(id)
		if obj != null:
			var scanner_data = _node_id_scanner[id]
			_update_scanned_obj(obj, scanner_data)
			
func _update_scanned_obj(obj, scanner_data):
	if Globals.is_(Globals.get_data(scanner_data, "scanning.fully_mapped"), true):
		return
		
	var scan_radius = scanner_data.scanning.radius
	var cur_in_range = []
	var offset = Vector2(0,0)
	var obj_tile = Globals.LevelLoaderRef.World_to_Tile(obj.position)
	var scanned_tiles = []
	var bounds = Globals.LevelLoaderRef.levelSize
	
	while round(offset.length()) <= (scan_radius+1):
		while round(offset.length()) <= (scan_radius+1):
			#expanding in positive x & y then checking the other 3 quadrant
			#           |
			#        d  |  a
			#--------------------------
			#        c  |  b
			#           |
			#           |
			var tile = obj_tile + offset
			var obj_in_tile
			if round((tile - obj_tile).length()) > scan_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
				pass #obj.visible = false
			else:
				scanned_tiles.push_back(tile)
				obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
				for o in obj_in_tile:
					cur_in_range.push_back(o.get_attrib("unique_id"))
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if round((tile - obj_tile).length()) > scan_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
					pass #obj.visible = false
				else:
					scanned_tiles.push_back(tile)
					obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
					for o in obj_in_tile:
						cur_in_range.push_back(o.get_attrib("unique_id"))
			if offset.y != 0:
				offset.y *= -1
				tile = obj_tile + offset
				if round((tile - obj_tile).length()) > scan_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
					pass #obj.visible = false
				else:
					scanned_tiles.push_back(tile)
					obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
					for o in obj_in_tile:
						cur_in_range.push_back(o.get_attrib("unique_id"))
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if round((tile - obj_tile).length()) > scan_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
					pass #obj.visible = false
				else:
					scanned_tiles.push_back(tile)
					obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
					for o in obj_in_tile:
						cur_in_range.push_back(o.get_attrib("unique_id"))
			offset.y *= -1
			offset.y += 1
		offset.y = 0
		offset.x += 1

		
	var always_seen = Globals.get_data(scanner_data, "scanning.full_reveal_type", [])
	for type in always_seen:
		if type in Globals.LevelLoaderRef.objByType:
			for o in Globals.LevelLoaderRef.objByType[type]:
				var uniq_id = o.get_attrib("unique_id")
				if not uniq_id in cur_in_range:
					cur_in_range.push_back(uniq_id)


	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var old_range = obj.get_attrib("scanner_result.cur_in_range." + level_id)
	var new_in_range = []
	var new_out_of_range = []
	if old_range == null:
		new_in_range = cur_in_range
	else:
		for id in cur_in_range:
			if not id in old_range:
				new_in_range.push_back(id)
		for id in old_range:
			if not id in cur_in_range:
				new_out_of_range.push_back(id)
				
	var unkown_objects = []
	var partial_type = Globals.get_data(scanner_data, "scanning.partial_reveal_type", [])
	for type in partial_type:
		if type in Globals.LevelLoaderRef.objByType:
			for o in Globals.LevelLoaderRef.objByType[type]:
				unkown_objects.push_back(o.get_attrib("unique_id"))
				
			
	#if new_in_range.size() != 0 or new_out_of_range.size() != 0:
	#	# for now. Only send an event if the scanner result for the object has significant changes.
	obj.set_attrib("scanner_result.cur_in_range." + level_id, cur_in_range)
	obj.set_attrib("scanner_result.new_in_range." + level_id, new_in_range)
	obj.set_attrib("scanner_result.new_out_of_range." + level_id, new_out_of_range)
	obj.set_attrib("scanner_result.unknown." + level_id, unkown_objects)
	obj.set_attrib("scanner_result.scanned_tiles." + level_id, scanned_tiles)
	BehaviorEvents.emit_signal("OnScannerUpdated", obj)
	