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
	BehaviorEvents.connect("OnTriggerAnomaly", self, "OnTriggerAnomaly_Callback")
	BehaviorEvents.connect("OnAnomalyEffectGone", self, "OnAnomalyEffectGone_Callback")
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")

func OnTransferPlayer_Callback(old_player, new_player):
	var scanners = new_player.get_attrib("mounts.scanner")
	if scanners == null or scanners.size() <= 0:
		update_no_scanner(old_player, new_player)
		return
	
	var scanner_name = scanners[0]
	if scanner_name != null and scanner_name != "":
		var scanner_data = Globals.LevelLoaderRef.LoadJSON(scanner_name)
		_up_to_date = false
		special_update_ultimate(new_player, scanner_data)
	else:
		update_no_scanner(old_player, new_player)
		
func update_no_scanner(old_player, new_player):
	var level_id : String = Globals.LevelLoaderRef.GetLevelID()
	new_player.set_attrib("scanner_result.new_out_of_range." + level_id, old_player.get_attrib("scanner_result.cur_in_range." + level_id))
	new_player.set_attrib("scanner_result.cur_in_range." + level_id, [])
	new_player.set_attrib("scanner_result.new_in_range." + level_id, [])
	new_player.set_attrib("scanner_result.unknown." + level_id, [])
	new_player.set_attrib("scanner_result.unknown2." + level_id, [])
	BehaviorEvents.emit_signal("OnScannerUpdated", new_player)

func OnObjTurn_Callback(obj):
	if obj.get_attrib("type") == "player":
		do_anomaly_detection(obj)
		# need to make sure everything is invisible if we removed our scanner
		process_empty_scanner(obj)
	
func OnAnomalyEffectGone_Callback(obj, effect_data):
	if Globals.get_data(effect_data, "type") == "scanner":
		_up_to_date = false
	
func OnTriggerAnomaly_Callback(obj, anomaly):
	if anomaly.get_attrib("anomaly.scanner") != null:
		_up_to_date = false
	
func OnMountAdded_Callback(obj, slot, src, modified_attributes):
	if not "scanner" in slot:
		return
		
	var scanner_data = null
	if src != null and src != "":
		scanner_data = Globals.LevelLoaderRef.LoadJSON(src)
		_node_id_scanner[obj.get_attrib("unique_id")] = scanner_data
		_up_to_date = false
	
	special_update_ultimate(obj, scanner_data)
	
func OnMountRemoved_Callback(obj, slot, src, modified_attributes):
	if not "scanner" in slot:
		return
		
	var scanner_data = _node_id_scanner[obj.get_attrib("unique_id")]
	if scanner_data != null and Globals.is_(Globals.get_data(scanner_data, "scanning.fully_mapped"), true):
		var scanner_explored = get_node("../../ExploredBG")
		for x in range(Globals.LevelLoaderRef.levelSize.x):
			for y in range(Globals.LevelLoaderRef.levelSize.y):
				scanner_explored.set_cell(x,  y, 0)
		
	_node_id_scanner.erase(obj.get_attrib("unique_id"))
	_up_to_date = false
	
func OnLevelLoaded_Callback():
	var scanner_explored = get_node("../../ExploredBG")
	for x in range(Globals.LevelLoaderRef.levelSize.x):
		for y in range(Globals.LevelLoaderRef.levelSize.y):
			scanner_explored.set_cell(x,  y, 0)
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
		_up_to_date = false
		special_update_ultimate(obj, scanner_data)
	
func OnRequestObjectUnload_Callback(obj):
	_node_id_scanner.erase(obj.get_attrib("unique_id"))

func process_empty_scanner(obj):
	var scanners = obj.get_attrib("mounts.scanner")
	if scanners == null or scanners.size() <= 0:
		return
		
	var scanner_name = scanners[0]
	if scanner_name == null or scanner_name == "":
		var level_id = Globals.LevelLoaderRef.GetLevelID()
		var cur_in_range = obj.get_attrib("scanner_result.cur_in_range." + level_id, [])
		if cur_in_range.size() > 0:
			obj.set_attrib("scanner_result.new_out_of_range." + level_id, cur_in_range)
			obj.set_attrib("scanner_result.cur_in_range." + level_id, [])
			BehaviorEvents.emit_signal("OnScannerUpdated", obj)
	

func do_anomaly_detection(obj):
	var unique_id : int = obj.get_attrib("unique_id")
	# If the player doesn't have a scanner equipped, we do not do anomaly detection
	if not unique_id in _node_id_scanner:
		return
	var scanner_data = _node_id_scanner[unique_id]
	var bonus : float = Globals.get_data(scanner_data, "scanning.detection_bonus", 0.0)
	var level_id : String = Globals.LevelLoaderRef.GetLevelID()
	var known_anomalies : Dictionary = obj.get_attrib("scanner_result.known_anomalies." + level_id, {})
	var detectable_obj = obj.get_attrib("scanner_result.cur_in_range." + level_id, [])
	var last_check_turn : float = obj.get_attrib("scanner_result.last_anomaly_check", Globals.total_turn - 1.0)
	var turn_elapsed : float = Globals.total_turn - last_check_turn
	var whole : int = floor(turn_elapsed)
	var frac : float = turn_elapsed - whole
	obj.set_attrib("scanner_result.last_anomaly_check", Globals.total_turn - frac)
	for i in range(whole):
		for id in detectable_obj:
			var o : Attributes = Globals.LevelLoaderRef.objById[id]
			if o != null and o.get_attrib("type") == "anomaly" and (not id in known_anomalies or known_anomalies[id] == false):
				var chance = o.get_attrib("anomaly.base_detection_chance")
				chance += bonus
				if MersenneTwister.rand_float() < chance:
					known_anomalies[id] = true
					o.visible = true
					if obj.get_attrib("type") == "player":
						BehaviorEvents.emit_signal("OnLogLine", "Scanners have discovered an Anomaly close by")
						
	obj.set_attrib("scanner_result.known_anomalies." + level_id, known_anomalies)

func special_update_ultimate(obj, scanner_data):
	if scanner_data != null and Globals.is_(Globals.get_data(scanner_data, "scanning.fully_mapped"), true):
		var scanner_border = get_node("../../ScannerBorder")
		scanner_border.clear()
		var level_id : String = Globals.LevelLoaderRef.GetLevelID()
		var old_range : Array = obj.get_attrib("scanner_result.cur_in_range." + level_id, [])
		var cur_in_range := []
		for key in Globals.LevelLoaderRef.objById:
			var o : Node2D = Globals.LevelLoaderRef.objById[key]
			# Removed objects just get set to null so we might have null obj in objById
			if o != null and o != obj:
				cur_in_range.push_back(o.get_attrib("unique_id"))
			
		obj.set_attrib("scanner_result.cur_in_range." + level_id, cur_in_range)
		
		obj.set_attrib("scanner_result.new_in_range." + level_id, [])
		obj.set_attrib("scanner_result.new_out_of_range." + level_id, [])
		obj.set_attrib("scanner_result.unknown." + level_id, [])
		obj.set_attrib("scanner_result.unknown2." + level_id, [])
	
func _process(delta):
	if _up_to_date == true:
		return
		
	for id in _node_id_scanner:
		var obj = Globals.LevelLoaderRef.GetObjectById(id)
		if obj != null:
			var scanner_data = _node_id_scanner[id]
			_update_scanned_obj(obj, scanner_data)
	
	# Put it at the end because when we update ghosts in _updated_scanned_obj we might change their
	# position which will trigger another scanner update if we're not careful		
	_up_to_date = true
			
func _update_scanned_obj(obj, scanner_data):
	if Globals.is_(Globals.get_data(scanner_data, "scanning.fully_mapped"), true):
		return
		
		
	var scan_radius = scanner_data.scanning.radius
	var scan_bonus = obj.get_attrib("scanner_result.range_bonus", 0)
	scan_radius += scan_bonus
	var obj_tile = Globals.LevelLoaderRef.World_to_Tile(obj.position)
	var bounds = Globals.LevelLoaderRef.levelSize
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	
	# Perf Hack: AIs for now don't really need scanner, they just need to check if the player is in their "vision" range
	if obj.get_attrib("type") != "player":
		var player_new_range = []
		var player_cur_range = []
		var all_players = []
		var old_range = obj.get_attrib("scanner_result.cur_in_range." + level_id, [])
		if "player" in Globals.LevelLoaderRef.objByType and Globals.LevelLoaderRef.objByType["player"].size() > 0:
			all_players = Globals.LevelLoaderRef.objByType["player"]
		for p in all_players:
			var p_tile = Globals.LevelLoaderRef.World_to_Tile(p.position)
			if _is_in_range(obj_tile, p_tile, scan_radius, bounds):
				var id = p.get_attrib("unique_id")
				if id in old_range:
					player_cur_range.push_back(id)
				else:
					player_new_range.push_back(id)
					player_cur_range.push_back(id)
					
		obj.set_attrib("scanner_result.cur_in_range." + level_id, player_cur_range)
		obj.set_attrib("scanner_result.new_in_range." + level_id, player_new_range)
		BehaviorEvents.emit_signal("OnScannerUpdated", obj)
		return
		
	var last_frame_tiles = obj.get_attrib("scanner_result.scanned_tiles." + level_id, [])
	obj.set_attrib("scanner_result.previous_scanned_tiles." + level_id, last_frame_tiles)
	
	var scanner_explored = get_node("../../ExploredBG")
	var fow = get_node("../../FoW")
	#var last_frame_tiles = obj.get_attrib("scanner_result.scanned_tiles." + level_id, [])
	for t in last_frame_tiles:
		if typeof(t) == TYPE_STRING:
			t = str2var("Vector2" + t)
		scanner_explored.set_cell(t.x, t.y, 0)
		#fow.TagTile(t)
	
	var cur_in_range = []
	var offset = Vector2(0,0)
	var scanned_tiles = []
	var scanner_border = get_node("../../ScannerBorder")
	scanner_border.clear()
	
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
				scanner_border.set_cell(tile.x, tile.y, 0)
				scanner_explored.set_cell(tile.x, tile.y, -1)
				#fow.TagTile(tile)
				obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
				for o in obj_in_tile:
					if o == obj:
						continue
					cur_in_range.push_back(o.get_attrib("unique_id"))
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if round((tile - obj_tile).length()) > scan_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
					pass #obj.visible = false
				else:
					scanned_tiles.push_back(tile)
					scanner_border.set_cell(tile.x, tile.y, 0)
					scanner_explored.set_cell(tile.x, tile.y, -1)
					#fow.TagTile(tile)
					obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
					for o in obj_in_tile:
						if o == obj:
							continue
						cur_in_range.push_back(o.get_attrib("unique_id"))
			if offset.y != 0:
				offset.y *= -1
				tile = obj_tile + offset
				if round((tile - obj_tile).length()) > scan_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
					pass #obj.visible = false
				else:
					scanned_tiles.push_back(tile)
					scanner_border.set_cell(tile.x, tile.y, 0)
					scanner_explored.set_cell(tile.x, tile.y, -1)
					#fow.TagTile(tile)
					obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
					for o in obj_in_tile:
						if o == obj:
							continue
						cur_in_range.push_back(o.get_attrib("unique_id"))
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if offset.y == 0 or round((tile - obj_tile).length()) > scan_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
					pass #obj.visible = false
				else:
					scanned_tiles.push_back(tile)
					scanner_border.set_cell(tile.x, tile.y, 0)
					scanner_explored.set_cell(tile.x, tile.y, -1)
					#fow.TagTile(tile)
					obj_in_tile = Globals.LevelLoaderRef.GetTile(tile)
					for o in obj_in_tile:
						if o == obj:
							continue
						cur_in_range.push_back(o.get_attrib("unique_id"))
			offset.y *= -1
			offset.y += 1
		offset.y = 0
		offset.x += 1

	scanner_border.update_bitmask_region(Vector2(0,0), Vector2(80,80))

	var unkown_objects2 = []
	var partial_type2 = Globals.get_data(scanner_data, "scanning.full_reveal_type", [])
	for type in partial_type2:
		if type in Globals.LevelLoaderRef.objByType:
			for o in Globals.LevelLoaderRef.objByType[type]:
				unkown_objects2.push_back(o.get_attrib("unique_id"))
		
	#var always_seen = Globals.get_data(scanner_data, "scanning.full_reveal_type", [])
	#for type in always_seen:
	#	if type in Globals.LevelLoaderRef.objByType:
	#		for o in Globals.LevelLoaderRef.objByType[type]:
	#			var uniq_id = o.get_attrib("unique_id")
	#			if not uniq_id in cur_in_range:
	#				cur_in_range.push_back(uniq_id)


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
				# Object (like a ship) could have been deleted
				if Globals.LevelLoaderRef.GetObjectById(id) != null:
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
	obj.set_attrib("scanner_result.unknown2." + level_id, unkown_objects2)
	obj.set_attrib("scanner_result.scanned_tiles." + level_id, scanned_tiles)
	BehaviorEvents.emit_signal("OnScannerUpdated", obj)
	

func _is_in_range(obj_tile, tile, scan_radius, bounds):
	if round((tile - obj_tile).length()) > scan_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
		return false
	else:
		return true
