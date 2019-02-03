extends Node

export(NodePath) var Occluder

var _playerNode = null
onready var _occluder_ref = get_node(Occluder)

func _ready():
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnScannerUpdated", self, "OnScannerUpdated_Callback")
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")

func OnLevelLoaded_Callback():
	# Give two frames for scanner to update
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	ExecuteFullSweep()
	
func OnTransferPlayer_Callback(old_player, new_player):
	_playerNode = new_player
	# Should I duplicate the array here ?
	new_player.set_attrib("memory", old_player.get_attrib("memory"))

func OnObjectLoaded_Callback(obj):
	if obj.get_attrib("type") == "player":
		_playerNode = obj
		BehaviorEvents.disconnect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
		BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	
func OnRequestObjectUnload_Callback(obj):
	if obj == _playerNode:
		_playerNode = null
		BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
		BehaviorEvents.disconnect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")

func ExecuteFullSweep():
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var player_scan = _playerNode.get_attrib("scanner_result.cur_in_range." + level_id)
	if player_scan == null: # Not sure why this can be null at this point but I crashed once there
		return
	for key in Globals.LevelLoaderRef.objById:
		var obj = Globals.LevelLoaderRef.objById[key]
		var disable_fow = Globals.LevelLoaderRef.GetCurrentLevelData().has("fully_mapped") and Globals.LevelLoaderRef.GetCurrentLevelData().fully_mapped == true
		if key in player_scan or obj == _playerNode or obj.get_attrib("ghost_memory") != null or disable_fow:
			obj.visible = true
		else:
			obj.visible = false

func _update_occlusion_texture():
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()
    
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var tile_memory = _playerNode.get_attrib("memory." + level_id + ".tiles")
	if tile_memory == null:
		dynImage.create(Globals.LevelLoaderRef.levelSize.x,Globals.LevelLoaderRef.levelSize.y,false,Image.FORMAT_R8)
		dynImage.fill(Color(1.0,1.0,1.0,1.0))
	else:
		dynImage.create_from_data(Globals.LevelLoaderRef.levelSize.x,Globals.LevelLoaderRef.levelSize.y,false,Image.FORMAT_R8, tile_memory)
    
	imageTexture.create_from_image(dynImage)
	_occluder_ref.texture = imageTexture
	imageTexture.resource_name = "The created texture!"

func _tag_tile(tile):
	if tile.x >= Globals.LevelLoaderRef.levelSize.x or tile.y >= Globals.LevelLoaderRef.levelSize.y or tile.x < 0 or tile.y < 0:
		return
	
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var tile_memory = _playerNode.get_attrib("memory." + level_id + ".tiles")
	if tile_memory == null:
		tile_memory = []
		for x in range(Globals.LevelLoaderRef.levelSize.x):
			for y in range(Globals.LevelLoaderRef.levelSize.y):
				tile_memory.push_back(255.0)
				
	var player_tile = Globals.LevelLoaderRef.World_to_Tile(_playerNode.position)
	tile_memory[(tile.y * Globals.LevelLoaderRef.levelSize.x) + tile.x] = 0.0
		
	_playerNode.set_attrib("memory." + level_id + ".tiles", tile_memory)

func _update_occlusion(o):
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var scanned_tiles = o.get_attrib("scanner_result.scanned_tiles." + level_id)
	for t in scanned_tiles:
		_tag_tile(t)
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
		BehaviorEvents.emit_signal("OnRequestObjectUnload", ref_obj)

func OnScannerUpdated_Callback(obj):
	if obj != _playerNode:
		return
		
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var new_objs = obj.get_attrib("scanner_result.new_in_range." + level_id)
	var new_out_objs = obj.get_attrib("scanner_result.new_out_of_range." + level_id)
	
	for id in new_objs:
		var o = Globals.LevelLoaderRef.GetObjectById(id)
		if o != null:
			o.visible = true
		if o != null and o.get_attrib("has_ghost_memory"):
			_remove_ghost_from_real(o)
		if o != null and o.get_attrib("ghost_memory"):
			_remove_ghost(o)
	
	for id in new_out_objs:
		var o = Globals.LevelLoaderRef.GetObjectById(id)
		if o != null and o.get_attrib("ghost_memory") == null:
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
			
			# UPDATE PLAYER MEMORY
			#var obj_tile = Globals.LevelLoaderRef.World_to_Tile(o.position)
			#var player_tile = Globals.LevelLoaderRef.World_to_Tile(_playerNode.position)
			#var data = {"position":var2str(obj_tile), "sprite":obj.get_attrib("sprite")}
			#var path = "memory.objects." + str(obj.get_attrib("unique_id"))
			#_playerNode.set_attrib(path, data)
			
	_update_occlusion(obj)