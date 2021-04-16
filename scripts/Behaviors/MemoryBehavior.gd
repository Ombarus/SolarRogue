extends Node

export(NodePath) var Occluder

var _playerNode = null
var _dirty_occlusion := true
var default_occluder_color : Color
onready var _occluder_ref = get_node(Occluder)

const fow_ref = "../../BG/FoW"

func _ready():
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnScannerUpdated", self, "OnScannerUpdated_Callback")
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnPositionUpdated", self, "OnPositionUpdated_Callback")
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	
	if _occluder_ref != null:
		default_occluder_color = _occluder_ref.modulate


func OnPositionUpdated_Callback(obj):
	if obj.get_attrib("type") == "player":
		_dirty_occlusion = true

func OnMountAdded_Callback(obj, slot, src, modified_attributes):
	if not "scanner" in slot:
		return
		
	ExecuteFullSweep()
	
	
func OnMountRemoved_Callback(obj, slot, src, modified_attributes):
	if not "scanner" in slot or obj.get_attrib("type") != "player":
		return

	_dirty_occlusion = true

func OnLevelLoaded_Callback():
	var level_data = Globals.LevelLoaderRef.GetCurrentLevelData()
	var updated_fog_color : Color = default_occluder_color
	if level_data.has("fog_color_override") == true:
		var col_array = level_data["fog_color_override"]
		updated_fog_color = Color(col_array[0], col_array[1], col_array[2], col_array[3])
	_occluder_ref.modulate = updated_fog_color
	#_occluder_ref.material.set_shader_param("gray_color", updated_fog_color)

	if has_node(fow_ref):
		var fow = get_node(fow_ref)
		fow.ResetUV()
	
	# Give two frames for scanner to update
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	ExecuteFullSweep()
	if _playerNode != null:
		OnScannerUpdated_Callback(_playerNode)
	
func OnTransferPlayer_Callback(old_player, new_player):
	_playerNode = new_player
	# Should I duplicate the array here ?
	new_player.set_attrib("memory", old_player.get_attrib("memory"))
	new_player.visible = true # in case previous ship didn't have scanner and couldn't see the ship
	if new_player.get_attrib("has_ghost_memory") != null:
		_remove_ghost_from_real(new_player)
	#_dirty_occlusion = true
	_update_occlusion_texture()
	ExecuteFullSweep()
	#_update_occlusion(new_player)

func OnObjectLoaded_Callback(obj):
	if obj.get_attrib("type") == "player":
		_playerNode = obj
		#BehaviorEvents.disconnect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
		BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
		_update_occlusion_texture()
	elif _playerNode != null:
		var scanners = Globals.LevelLoaderRef.LoadJSONArray(_playerNode.get_attrib("mounts.scanner"))
		var is_ultimate : bool = false
		var level_id = Globals.LevelLoaderRef.GetLevelID()
		var player_scan = _playerNode.get_attrib("scanner_result.cur_in_range." + level_id)
		var known_anomalies = _playerNode.get_attrib("scanner_result.known_anomalies." + level_id, {})
		var key = obj.get_attrib("unique_id")
		for s_data in scanners:
			if Globals.is_(Globals.get_data(s_data, "scanning.fully_mapped"), true):
				is_ultimate = true
				break
				
		_dirty_occlusion = true
		var disable_fow = is_ultimate or (Globals.LevelLoaderRef.GetCurrentLevelData().has("fully_mapped") and Globals.LevelLoaderRef.GetCurrentLevelData().fully_mapped == true)
		var not_invisible_anomaly : bool = obj.get_attrib("type") != "anomaly" or (key in known_anomalies and known_anomalies[key] == true)
		var is_player : bool = obj == _playerNode
		var is_a_ghost : bool = obj.get_attrib("ghost_memory") != null or obj.get_attrib("is_fake_ghost_memory", false) == true
		var in_scanner_range : bool = player_scan != null and key in player_scan
		
		if  not_invisible_anomaly and (disable_fow or is_player or is_a_ghost or in_scanner_range):
			obj.visible = true
			if obj != null and obj.get_attrib("has_ghost_memory"):
				_remove_ghost_from_real(obj)
		else:
			obj.visible = false
			
	
func OnRequestObjectUnload_Callback(obj):
	if obj == _playerNode:
		_playerNode = null
		BehaviorEvents.disconnect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")

func ExecuteFullSweep():
	_dirty_occlusion = true
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var player_scan = _playerNode.get_attrib("scanner_result.cur_in_range." + level_id)
	var known_anomalies = _playerNode.get_attrib("scanner_result.known_anomalies." + level_id, {})
	var is_ultimate : bool = false
	var scanners = Globals.LevelLoaderRef.LoadJSONArray(_playerNode.get_attrib("mounts.scanner"))

	for s_data in scanners:
		if Globals.is_(Globals.get_data(s_data, "scanning.fully_mapped"), true):
			is_ultimate = true
			break
		
	if has_node(fow_ref):
		var fow = get_node(fow_ref)
		if is_ultimate:
			fow.visible = false
		else:
			fow.visible = true
		
	for key in Globals.LevelLoaderRef.objById:
		var obj = Globals.LevelLoaderRef.objById[key]
		# Removed objects just get set to null so we might have null obj in objById
		if obj == null:
			continue
			
		var disable_fow = is_ultimate or (Globals.LevelLoaderRef.GetCurrentLevelData().has("fully_mapped") and Globals.LevelLoaderRef.GetCurrentLevelData().fully_mapped == true)
		var not_invisible_anomaly : bool = obj.get_attrib("type") != "anomaly" or (key in known_anomalies and known_anomalies[key] == true)
		var is_player : bool = obj == _playerNode
		var is_a_ghost : bool = obj.get_attrib("ghost_memory") != null or obj.get_attrib("is_fake_ghost_memory", false) == true
		var in_scanner_range : bool = player_scan != null and key in player_scan
		
		if  not_invisible_anomaly and (disable_fow or is_player or is_a_ghost or in_scanner_range):
			obj.visible = true
			if obj != null and obj.get_attrib("has_ghost_memory"):
				_remove_ghost_from_real(obj)
		else:
			obj.visible = false
		if disable_fow:
			var tile_memory : Array = []
			for x in range(Globals.LevelLoaderRef.levelSize.x + 2):
				for y in range(Globals.LevelLoaderRef.levelSize.y + 2):
					# tag as "explored" instead of "lit" for when we re-enable fow
					tile_memory.push_back(120.0)
					tile_memory.push_back(120.0)
					tile_memory.push_back(120.0)
					tile_memory.push_back(120.0)
			_playerNode.set_attrib("memory." + level_id + ".tiles", tile_memory)
			_update_occlusion_texture()

func _update_occlusion_texture():
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()
	
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var tile_memory = _playerNode.get_attrib("memory." + level_id + ".tiles")
	if tile_memory == null:
		dynImage.create(Globals.LevelLoaderRef.levelSize.x+2,Globals.LevelLoaderRef.levelSize.y+2,false,Image.FORMAT_RGBA8)
		dynImage.fill(Color(1.0,1.0,1.0,1.0))
	else:
		dynImage.create_from_data(Globals.LevelLoaderRef.levelSize.x+2,Globals.LevelLoaderRef.levelSize.y+2,false,Image.FORMAT_RGBA8, tile_memory)
	
	imageTexture.create_from_image(dynImage)
	_occluder_ref.texture = imageTexture
	imageTexture.resource_name = "The created texture!"
	
	if tile_memory != null and has_node(fow_ref):
		var fow = get_node(fow_ref)
		fow.UpdateDirtyTiles(tile_memory)
	
	

func _tag_tile(tile, tile_memory, val = 0.0):
	if tile.x >= Globals.LevelLoaderRef.levelSize.x or tile.y >= Globals.LevelLoaderRef.levelSize.y or tile.x < 0 or tile.y < 0:
		return
	
	#var level_id = Globals.LevelLoaderRef.GetLevelID()
	#var tile_memory = _playerNode.get_attrib("memory." + level_id + ".tiles")
				
	tile_memory[(((tile.y+1) * (Globals.LevelLoaderRef.levelSize.x+2)) + (tile.x+1))*4+0] = val
	tile_memory[(((tile.y+1) * (Globals.LevelLoaderRef.levelSize.x+2)) + (tile.x+1))*4+1] = val
	tile_memory[(((tile.y+1) * (Globals.LevelLoaderRef.levelSize.x+2)) + (tile.x+1))*4+2] = val
	tile_memory[(((tile.y+1) * (Globals.LevelLoaderRef.levelSize.x+2)) + (tile.x+1))*4+3] = val
	#_playerNode.set_attrib("memory." + level_id + ".tiles", tile_memory)

func _update_occlusion(o):
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var scanned_tiles = o.get_attrib("scanner_result.scanned_tiles." + level_id, [])
	var prev_scanned_tiles = o.get_attrib("scanner_result.previous_scanned_tiles." + level_id, [])
	
	var fow = null
	if has_node(fow_ref):
		fow = get_node(fow_ref)
	var tile_memory = _playerNode.get_attrib("memory." + level_id + ".tiles")
	
	if tile_memory == null:
		tile_memory = []
		for x in range(Globals.LevelLoaderRef.levelSize.x + 2):
			for y in range(Globals.LevelLoaderRef.levelSize.y + 2):
				if x == 0 or y == 0 or x == Globals.LevelLoaderRef.levelSize.x+1 or y == Globals.LevelLoaderRef.levelSize.y + 1:
					tile_memory.push_back(0.0) # having issues on iOS with R8 and gles2... trying to force RGBA8
					tile_memory.push_back(0.0)
					tile_memory.push_back(0.0)
					tile_memory.push_back(0.0)
				else:
					tile_memory.push_back(255.0)
					tile_memory.push_back(255.0)
					tile_memory.push_back(255.0)
					tile_memory.push_back(255.0)
					
	for t in prev_scanned_tiles:
		# Storage type bug in the savefile...
		if typeof(t) == TYPE_STRING:
			t = str2var("Vector2" + t)
		if not t in scanned_tiles:
			_tag_tile(t, tile_memory, 120.0) # explored, grayed-out
			if fow != null:
				fow.TagTile(t)
	
	for t in scanned_tiles:
		if typeof(t) == TYPE_STRING:
			t = str2var("Vector2" + t)
		_tag_tile(t, tile_memory) # "lit" tile
		if fow != null:
			fow.TagTile(t)
		
	_playerNode.set_attrib("memory." + level_id + ".tiles", tile_memory)
	_update_occlusion_texture()
	
	
func _remove_ghost(ghost):
	var ref_obj = Globals.LevelLoaderRef.GetObjectById(ghost.get_attrib("ghost_memory.reference_id"))
	
	if ref_obj != null:
		ref_obj.modified_attributes.erase("has_ghost_memory")
	BehaviorEvents.emit_signal("OnRequestObjectUnload", ghost)
	
func _remove_ghost_from_real(real):
	var ref_id = real.get_attrib("has_ghost_memory.reference_id")
	var ref_obj = Globals.LevelLoaderRef.GetObjectById(ref_id)
	if ref_obj != null:
		real.modified_attributes.erase("has_ghost_memory")
		BehaviorEvents.emit_signal("OnRequestObjectUnload", ref_obj)

func OnScannerUpdated_Callback(obj):
	if obj != _playerNode:
		return
		
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var new_objs = obj.get_attrib("scanner_result.new_in_range." + level_id, [])
	var new_out_objs = obj.get_attrib("scanner_result.new_out_of_range." + level_id, [])
	var unkown_objs = obj.get_attrib("scanner_result.unknown." + level_id, [])
	var unkown_objs2 = obj.get_attrib("scanner_result.unknown2." + level_id, [])
	var known_anomalies = obj.get_attrib("scanner_result.known_anomalies." + level_id, {})
	
	for id in new_objs:
		var o = Globals.LevelLoaderRef.GetObjectById(id)
		if o != null:
			var anomaly_detected = o.get_attrib("type") != "anomaly" or (id in known_anomalies and known_anomalies[id] == true)
			o.visible = anomaly_detected
		if o != null and o.get_attrib("has_ghost_memory"):
			_remove_ghost_from_real(o)
		if o != null and o.get_attrib("ghost_memory"):
			_remove_ghost(o)
		if o != null and o.get_attrib("is_fake_ghost_memory", false) == true:
			o.set_attrib("is_fake_ghost_memory", false)
	
	for id in new_out_objs:
		var o = Globals.LevelLoaderRef.GetObjectById(id)
		var anomaly_detected = o != null and (o.get_attrib("type") != "anomaly" or (id in known_anomalies and known_anomalies[id] == true))
		if o != null and o.get_attrib("ghost_memory") == null and anomaly_detected == true and o.get_attrib("no_ghost") != true:
			if o.get_attrib("has_ghost_memory") != null:
				print("WOAH WTF BBQ !")
			# CREATE A GHOST
			o.visible = false
			# no better way to deep copy a dictionary I think
			var modified_copy = JSON.parse(to_json(o.modified_attributes)).result
			modified_copy["ghost_memory"] = {"reference_id":o.get_attrib("unique_id")}
			modified_copy.erase("unique_id") # let it generate a new unique_id
			modified_copy["action_point"] = {"disabled":true}
			var n = Globals.LevelLoaderRef.RequestObject(o.get_attrib("src"), Globals.LevelLoaderRef.World_to_Tile(o.position), modified_copy)
			n.set_attrib("ai.disabled", true) # trick way to disable a component from base_attributes because I cannot remove stuff from it
			n.rotation =  o.rotation
			o.set_attrib("has_ghost_memory.reference_id", n.get_attrib("unique_id"))
		elif o != null and o.get_attrib("no_ghost") == true:
			o.set_attrib("is_fake_ghost_memory", true)
	
	if unkown_objs != null:
		#var all_visible = _playerNode.get_attrib("scanner_result.cur_in_range." + level_id, [])
		for id in unkown_objs:
			var o = Globals.LevelLoaderRef.GetObjectById(id)
			
			if o != null and o.visible == false and o.get_attrib("ghost_memory") == null:
				if o.get_attrib("has_ghost_memory") != null:
					var ghost_id = o.get_attrib("has_ghost_memory.reference_id")
					var ghost = Globals.LevelLoaderRef.GetObjectById(ghost_id)
					Globals.LevelLoaderRef.UpdatePosition(ghost, o.position, true)
					if ghost.get_attrib("ghost_memory.is_unknown", false) == false:
						ghost.rotation = o.rotation
					#ghost.position = o.position # Don't ever ever do this with a Attribute Object... LevelLoader will get confused
				elif o.get_attrib("is_fake_ghost_memory", false) == false:
					var unkown_tile_path = "data/json/props/unknow.json"
					var modified = {}
					modified["ghost_memory"] = {"reference_id":o.get_attrib("unique_id"), "is_unknown":true}
					var n = Globals.LevelLoaderRef.RequestObject(unkown_tile_path, Globals.LevelLoaderRef.World_to_Tile(o.position), modified)
					o.set_attrib("has_ghost_memory.reference_id", n.get_attrib("unique_id"))
	
	if unkown_objs2 != null:
		#var all_visible = _playerNode.get_attrib("scanner_result.cur_in_range." + level_id, [])
		for id in unkown_objs2:
			var o = Globals.LevelLoaderRef.GetObjectById(id)
			
			if o != null and o.visible == false and o.get_attrib("ghost_memory") == null:
				if o.get_attrib("has_ghost_memory") != null:
					var ghost_id = o.get_attrib("has_ghost_memory.reference_id")
					var ghost = Globals.LevelLoaderRef.GetObjectById(ghost_id)
					if ghost != null:
						Globals.LevelLoaderRef.UpdatePosition(ghost, o.position, true)
						if ghost.get_attrib("ghost_memory.is_unknown", false) == false:
							ghost.rotation = o.rotation
					#ghost.position = o.position # Don't ever ever do this with a Attribute Object... LevelLoader will get confused
				elif o.get_attrib("is_fake_ghost_memory", false) == false:
					var unkown_tile_path = "data/json/props/unknow2.json"
					var modified = {}
					modified["ghost_memory"] = {"reference_id":o.get_attrib("unique_id"), "is_unknown":true}
					var n = Globals.LevelLoaderRef.RequestObject(unkown_tile_path, Globals.LevelLoaderRef.World_to_Tile(o.position), modified)
					o.set_attrib("has_ghost_memory.reference_id", n.get_attrib("unique_id"))		
	
	if _dirty_occlusion:
		_update_occlusion(obj)
		_dirty_occlusion = false
