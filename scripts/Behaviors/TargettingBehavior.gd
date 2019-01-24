extends Node

var _callback_obj = null
var _callback_method = null
var _click_start_pos
var _playerNode = null
var _weapon = null

func _ready():
	BehaviorEvents.connect("OnRequestPlayerTargetting", self, "OnRequestPlayerTargetting_Callback")
	BehaviorEvents.connect("OnRequestBoardTargetting", self, "OnRequestBoardTargetting_Callback")
	BehaviorEvents.connect("OnTargetClick", self, "OnTargetClick_Callback")
	BehaviorEvents.connect("OnBoardTargetClick", self, "OnBoardTargetClick_Callback")
	
func ClearOverlay():
	var overlay_nodes = get_tree().get_nodes_in_group("overlay")
	for n in overlay_nodes:
		n.get_parent().remove_child(n)
		n.queue_free()
	
	
func OnRequestPlayerTargetting_Callback(player, weapon, callback_obj, callback_method):
	_callback_obj = callback_obj
	_callback_method = callback_method
	_playerNode = player
	_weapon = weapon
	
	_DoTargetting(player, weapon)
	
func OnRequestBoardTargetting_Callback(player, callback_obj, callback_method):
	_callback_obj = callback_obj
	_callback_method = callback_method
	_playerNode = player
	
	# custom info for targetting a ship to board
	var targetting_data = {"weapon_data":{"fire_range":1, "fire_pattern":"o"}}
	_weapon = targetting_data
	
	_DoTargetting(player, targetting_data)
		
		
func OnBoardTargetClick_Callback(click_pos):
	ClearOverlay()
	
	var tile = Globals.LevelLoaderRef.World_to_Tile(click_pos)
	var tile_content = Globals.LevelLoaderRef.levelTiles[tile.x][tile.y]
	var potential_targets = []
	for obj in tile_content:
		if obj.get_attrib("boardable") == true and obj != _playerNode:
			potential_targets.push_back(obj)
	if potential_targets.size() == 1:
		#TODO: pass the right data for the weapon
		#TODO: Check if player has an equiped weapon
		var player_tile = Globals.LevelLoaderRef.World_to_Tile(_playerNode.position)
		if IsValidTile(player_tile, tile, _weapon.weapon_data):
			BehaviorEvents.emit_signal("OnTransferPlayer", _playerNode, tile_content[0])
		else:
			BehaviorEvents.emit_signal("OnLogLine", "Ship must be closer")
	elif potential_targets.size() == 0:
		BehaviorEvents.emit_signal("OnLogLine", "Ship transfer canceled")
	else:
		#TODO: choose target popup dialog
		pass
	
	#TODO: decide target here then notify player
	_callback_obj.call(_callback_method, click_pos)
		
func OnTargetClick_Callback(click_pos):
	ClearOverlay()
	
	var tile = Globals.LevelLoaderRef.World_to_Tile(click_pos)
	var tile_content = Globals.LevelLoaderRef.levelTiles[tile.x][tile.y]
	var potential_targets = []
	for obj in tile_content:
		if obj.get_attrib("destroyable") != null || obj.get_attrib("harvestable") != null:
			potential_targets.push_back(obj)
	if potential_targets.size() == 1:
		#TODO: pass the right data for the weapon
		#TODO: Check if player has an equiped weapon
		var player_tile = Globals.LevelLoaderRef.World_to_Tile(_playerNode.position)
		if IsValidTile(player_tile, tile, _weapon.weapon_data):
			BehaviorEvents.emit_signal("OnDealDamage", tile_content[0], _playerNode, _weapon)
		else:
			BehaviorEvents.emit_signal("OnLogLine", "Target is outside of our ship's weapon sir !")
	elif potential_targets.size() == 0:
		BehaviorEvents.emit_signal("OnLogLine", "There's nothing there sir...")
	else:
		#TODO: choose target popup dialog
		pass
	
	#TODO: decide target here then notify player
	_callback_obj.call(_callback_method, click_pos)

func IsValidTile(player_tile, target_tile, weapon_data):
	var bounds = Globals.LevelLoaderRef.levelSize
	var fire_radius = weapon_data.fire_range
	if weapon_data.fire_pattern == "o":
		if round((target_tile - player_tile).length()) > fire_radius or target_tile.x < 0 or target_tile.x > bounds.x or target_tile.y < 0 or target_tile.y > bounds.y:
			return false
		else:
			return true
	if weapon_data.fire_pattern == "+":
		if round((target_tile - player_tile).length()) > fire_radius or target_tile.x < 0 or target_tile.x > bounds.x or target_tile.y < 0 or target_tile.y > bounds.y or (player_tile.x != target_tile.x and player_tile.y != target_tile.y):
			return false
		else:
			return true
	
func ClosestFiringSolution(shooter_tile, target_tile, weapon):
	var shootable_tiles = []
	var fire_radius = weapon.weapon_data.fire_range
	var offset = Vector2(0,0)
	var obj_tile = shooter_tile
	var bounds = Globals.LevelLoaderRef.levelSize
	
	while round(offset.length()) <= (fire_radius+1):
		while round(offset.length()) <= (fire_radius+1):
			var tile = obj_tile + offset
			if IsValidTile(obj_tile, tile, weapon.weapon_data):
				shootable_tiles.append(tile)
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if IsValidTile(obj_tile, tile, weapon.weapon_data):
					shootable_tiles.append(tile)
			if offset.y != 0:
				offset.y *= -1
				tile = obj_tile + offset
				if IsValidTile(obj_tile, tile, weapon.weapon_data):
					shootable_tiles.append(tile)
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if IsValidTile(obj_tile, tile, weapon.weapon_data):
					shootable_tiles.append(tile)
			offset.y *= -1
			offset.y += 1
		offset.y = 0
		offset.x += 1
		
	var min_length = null
	var best_dist = null
	for tile in shootable_tiles:
		var dist = target_tile - tile
		var length = dist.length()
		if min_length == null or min_length > length:
			min_length = length
			best_dist = dist
			
	return best_dist
		

func _DoTargetting(player, weapon):
	var scene = load("res://scenes/tileset_source/targetting_reticle.tscn")
	var player_tile = Globals.LevelLoaderRef.World_to_Tile(player.position)
	var r = get_node("/root/Root/OverlayTiles")
	var n = null
	var fire_radius = weapon.weapon_data.fire_range
	var offset = Vector2(0,0)
	var obj_tile = player_tile
	var bounds = Globals.LevelLoaderRef.levelSize
	
	while round(offset.length()) <= (fire_radius+1):
		while round(offset.length()) <= (fire_radius+1):
			#expanding in positive x & y then checking the other 3 quadrant
			#           |
			#        d  |  a
			#--------------------------
			#        c  |  b
			#           |
			#           |
			var tile = obj_tile + offset
			if IsValidTile(obj_tile, tile, weapon.weapon_data):
				n = scene.instance()
				r.call_deferred("add_child", n)
				n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
				n.add_to_group("overlay")
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if IsValidTile(obj_tile, tile, weapon.weapon_data):
					n = scene.instance()
					r.call_deferred("add_child", n)
					n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
					n.add_to_group("overlay")
			if offset.y != 0:
				offset.y *= -1
				tile = obj_tile + offset
				if IsValidTile(obj_tile, tile, weapon.weapon_data):
					n = scene.instance()
					r.call_deferred("add_child", n)
					n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
					n.add_to_group("overlay")
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if IsValidTile(obj_tile, tile, weapon.weapon_data):
					n = scene.instance()
					r.call_deferred("add_child", n)
					n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
					n.add_to_group("overlay")
			offset.y *= -1
			offset.y += 1
		offset.y = 0
		offset.x += 1