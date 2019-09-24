extends Node

export(NodePath) var TargettingHUD

var _callback_obj = null
var _callback_method = null
var _player_node = null
var _targetting_data = null
var _last_clicked_tile = null

onready var _targetting_hud = get_node(TargettingHUD)

func _ready():
	BehaviorEvents.connect("OnRequestTargettingOverlay", self, "OnRequestTargettingOverlay_Callback")
	BehaviorEvents.connect("OnTargetClick", self, "OnTargetClick_Callback")
	
	_targetting_hud.connect("skip_pressed", self, "skip_pressed_Callback")
	_targetting_hud.connect("cancel_pressed", self, "ClearOverlay")
	
	
func skip_pressed_Callback():
	ClearOverlay()
	_callback_obj.call(_callback_method, null, null)
	
func ClearOverlay():
	var overlay_nodes = get_tree().get_nodes_in_group("overlay")
	for n in overlay_nodes:
		n.get_parent().remove_child(n)
		n.queue_free()
		
	overlay_nodes = get_tree().get_nodes_in_group("overlay_mouse")
	for n in overlay_nodes:
		n.get_parent().remove_child(n)
		n.queue_free()
	
func OnRequestTargettingOverlay_Callback(player, targetting_data, callback_obj, callback_method):
	_callback_obj = callback_obj
	_callback_method = callback_method
	_player_node = player
	_targetting_data = targetting_data
	
	ClearOverlay()
	_DoTargetting(_player_node, _targetting_data)
	_DoAreaOverlay(_player_node, _targetting_data)
	
func _DoAreaOverlay(_player_node, targetting_data):
	var area_size : int = Globals.get_data(targetting_data, "weapon_data.area_effect")
	if area_size == null or area_size == 0:
		return
	
	var scene = Preloader.TargettingReticle
	var bounds = Globals.LevelLoaderRef.levelSize
	var r : Node2D = get_node("/root/Root/OverlayTiles/AreaOfEffect")
	var n : Node2D = null
	var mouse_tile : Vector2 = Globals.LevelLoaderRef.World_to_Tile(_player_node.get_global_mouse_position())
	for offset_x in range(-area_size, area_size+1):
		for offset_y in range(-area_size, area_size+1):
			var target_tile := Vector2(offset_x, offset_y)
			var target_tile_dist : float = round(target_tile.length())
			if target_tile_dist <= area_size:
				n = scene.instance()
				r.call_deferred("add_child", n)
				n.position = Globals.LevelLoaderRef.Tile_to_World(target_tile)
				n.add_to_group("overlay_mouse")
	
func OnTargetClick_Callback(click_pos, target_type):
	ClearOverlay()
	var tile = Globals.LevelLoaderRef.World_to_Tile(click_pos)
	var tile_content = _gather_tile_contents(tile, _targetting_data)
	var potential_targets = []
	for obj in tile_content:
		var obj_type = obj.get_attrib("type")
		if obj_type != "player" and target_type == Globals.VALID_TARGET.attack and (obj.get_attrib("destroyable") != null || obj.get_attrib("harvestable") != null):
			potential_targets.push_back(obj)
		elif obj_type != "player" and target_type == Globals.VALID_TARGET.board and obj.get_attrib("boardable") == true:
			potential_targets.push_back(obj)
		elif obj_type != "player" and target_type == Globals.VALID_TARGET.loot and Globals.is_(obj.get_attrib("cargo.transferable"), true):
			potential_targets.push_back(obj)
	if potential_targets.size() == 0:
		BehaviorEvents.emit_signal("OnLogLine", "There's nothing there sir...")
		_callback_obj.call(_callback_method, null, tile)
	else:
		var player_tile = Globals.LevelLoaderRef.World_to_Tile(_player_node.position)
		
		var area_size : int = Globals.get_data(_targetting_data, "weapon_data.area_effect")
		if area_size == null:
			area_size = 0
			
		if not IsValidTile(player_tile, tile, _targetting_data.weapon_data):
			BehaviorEvents.emit_signal("OnLogLine", "Target is outside of our range sir !")
			_callback_obj.call(_callback_method, null, tile)
		elif potential_targets.size() == 1:
			#TODO: pass the right data for the weapon
			_callback_obj.call(_callback_method, potential_targets[0], tile)
		elif potential_targets.size() > 0 and area_size > 0:
			_callback_obj.call(_callback_method, potential_targets, tile)
		else:
			_last_clicked_tile = tile
			BehaviorEvents.emit_signal("OnPushGUI", "SelectTarget", {"targets":potential_targets, "callback_object":self, "callback_method":"SelectTarget_Callback"})
	
func _gather_tile_contents(tile, targetting_data):
	var area_size : int = Globals.get_data(targetting_data, "weapon_data.area_effect")
	if area_size == null:
		area_size = 0
	var tile_content := []
	for x in range(tile.x - area_size, tile.x + area_size+1):
		for y in range(tile.y - area_size, tile.y + area_size+1):
			tile_content += Globals.LevelLoaderRef.levelTiles[x][y]
			
	return tile_content
	
func SelectTarget_Callback(selected_targets):
	if selected_targets.size() <= 0:
		_callback_obj.call(_callback_method, null, _last_clicked_tile)
	else:
		_callback_obj.call(_callback_method, selected_targets[0], _last_clicked_tile)
	
func IsValidTile(player_tile, target_tile, weapon_data):
	var bounds = Globals.LevelLoaderRef.levelSize
	var fire_radius = weapon_data.fire_range
	var fire_min_range = Globals.get_data(weapon_data, "fire_minimum_range")
	var target_tile_dist = round((target_tile - player_tile).length())
	if fire_min_range == null:
		fire_min_range = 0
	if weapon_data.fire_pattern == "o":
		if target_tile_dist < fire_min_range or target_tile_dist > fire_radius or target_tile.x < 0 or target_tile.x > bounds.x or target_tile.y < 0 or target_tile.y > bounds.y:
			return false
		else:
			return true
	if weapon_data.fire_pattern == "+":
		if target_tile_dist < fire_min_range or target_tile_dist > fire_radius or target_tile.x < 0 or target_tile.x > bounds.x or target_tile.y < 0 or target_tile.y > bounds.y or (player_tile.x != target_tile.x and player_tile.y != target_tile.y):
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
	var scene = Preloader.TargettingReticle
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
				if offset.y != 0 and IsValidTile(obj_tile, tile, weapon.weapon_data):
					n = scene.instance()
					r.call_deferred("add_child", n)
					n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
					n.add_to_group("overlay")
			offset.y *= -1
			offset.y += 1
		offset.y = 0
		offset.x += 1
		