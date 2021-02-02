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
	var area_size : int = Globals.get_data(targetting_data.weapon_data, "weapon_data.area_effect", 0)
	if area_size == 0:
		return
	
	var scene = Preloader.TargettingReticle
	var bounds = Globals.LevelLoaderRef.levelSize
	var r : Node2D = get_node("/root/Root/OverlayTiles/mouse_targetting")
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
	var player_tile = Globals.LevelLoaderRef.World_to_Tile(_player_node.position)
	var weapon_data = _targetting_data.weapon_data.weapon_data
	var weapon_attributes = _targetting_data.get("modified_attributes", {})
	var fire_radius = weapon_data.fire_range + Globals.EffectRef.GetBonusValue(_player_node, "", weapon_attributes, "range_bonus")
	for obj in tile_content:
		var obj_type = obj.get_attrib("type")
		var is_ghost = obj.get_attrib("ghost_memory") != null
		if not is_ghost and obj_type != "player" and\
			target_type == Globals.VALID_TARGET.attack and \
			(obj.get_attrib("destroyable") != null || \
			(obj.get_attrib("harvestable") != null and weapon_data.get("can_harvest", true) == true)):
			potential_targets.push_back(obj)
		elif not is_ghost and obj_type != "player" and target_type == Globals.VALID_TARGET.board and obj.get_attrib("boardable") == true:
			potential_targets.push_back(obj)
		elif not is_ghost and obj_type != "player" and target_type == Globals.VALID_TARGET.loot and Globals.is_(obj.get_attrib("cargo.transferable"), true):
			potential_targets.push_back(obj)
	if potential_targets.size() == 0:
		if Globals.get_data(weapon_data, "shoot_empty", false) == false:
			var log_choices = {
				"There's nothing there sir...":50,
				"Unable to resolve target...":50,
				"Target lock failed...":50,
				"You didn't touch the right square...":5
			}
			BehaviorEvents.emit_signal("OnLogLine", log_choices)
			_callback_obj.call(_callback_method, null, null)
		elif IsValidTile(fire_radius, player_tile, tile, _targetting_data):
			_callback_obj.call(_callback_method, null, tile)
		else:
			BehaviorEvents.emit_signal("OnLogLine", "Target is outside of our range sir !")
			_callback_obj.call(_callback_method, null, null)
	else:
		var area_size : int = Globals.get_data(weapon_data, "area_effect", 0)
			
		if not IsValidTile(fire_radius, player_tile, tile, _targetting_data):
			BehaviorEvents.emit_signal("OnLogLine", "Target is outside of our range sir !")
			_callback_obj.call(_callback_method, null, null)
		elif potential_targets.size() == 1:
			#TODO: pass the right data for the weapon
			_callback_obj.call(_callback_method, potential_targets[0], tile)
		elif potential_targets.size() > 0 and area_size > 0:
			_callback_obj.call(_callback_method, potential_targets, tile)
		else:
			_last_clicked_tile = tile
			BehaviorEvents.emit_signal("OnPushGUI", "SelectTarget", {"targets":potential_targets, "callback_object":self, "callback_method":"SelectTarget_Callback"})
	
func _gather_tile_contents(tile, targetting_data):
	var area_size : int = Globals.get_data(targetting_data.weapon_data, "weapon_data.area_effect", 0)
	var tile_content := []
	for x in range(tile.x - area_size, tile.x + area_size+1):
		for y in range(tile.y - area_size, tile.y + area_size+1):
			tile_content += Globals.LevelLoaderRef.GetTile(Vector2(x, y))
	return tile_content
	
func SelectTarget_Callback(selected_targets):
	if selected_targets.size() <= 0:
		_callback_obj.call(_callback_method, null, _last_clicked_tile)
	else:
		_callback_obj.call(_callback_method, selected_targets[0], _last_clicked_tile)
	
func IsValidTile(fire_radius, player_tile, target_tile, targetting_data):
	var weapon_data = targetting_data.weapon_data.weapon_data
	#var weapon_attributes = targetting_data.modified_attributes
	var bounds = Globals.LevelLoaderRef.levelSize
	#var fire_radius = weapon_data.fire_range + Globals.EffectRef.GetBonusValue(obj, "", weapon_attributes, "range_bonus")
	var fire_min_range = Globals.get_data(weapon_data, "fire_minimum_range", 0)
	var target_tile_dist = round((target_tile - player_tile).length())
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
	if weapon_data.fire_pattern == "*":
		var out_of_range : bool = target_tile_dist < fire_min_range or target_tile_dist > fire_radius or target_tile.x < 0 or target_tile.x > bounds.x or target_tile.y < 0 or target_tile.y > bounds.y
		var not_in_line : bool = not (player_tile.x == target_tile.x or player_tile.y == target_tile.y or abs(player_tile.x - target_tile.x) == abs(player_tile.y - target_tile.y))
		if out_of_range or not_in_line:
			return false
		else:
			return true
	
func ClosestFiringSolution(obj, shooter_tile, target_tile, weapon):
	var shootable_tiles = []
	var fire_radius = weapon.weapon_data.weapon_data.fire_range + Globals.EffectRef.GetBonusValue(obj, "", weapon.modified_attributes, "range_bonus")
	var area_size : int = Globals.get_data(weapon.weapon_data, "weapon_data.area_effect", 0)
	var offset = Vector2(0,0)
	var obj_tile = shooter_tile
	var bounds = Globals.LevelLoaderRef.levelSize
	
	while round(offset.length()) <= (fire_radius+1):
		while round(offset.length()) <= (fire_radius+1):
			var tile = obj_tile + offset
			if IsValidTile(fire_radius, obj_tile, tile, weapon):
				shootable_tiles.append(tile)
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if IsValidTile(fire_radius, obj_tile, tile, weapon):
					shootable_tiles.append(tile)
			if offset.y != 0:
				offset.y *= -1
				tile = obj_tile + offset
				if IsValidTile(fire_radius, obj_tile, tile, weapon):
					shootable_tiles.append(tile)
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if IsValidTile(fire_radius, obj_tile, tile, weapon):
					shootable_tiles.append(tile)
			offset.y *= -1
			offset.y += 1
		offset.y = 0
		offset.x += 1
		
	var min_length = null
	var best_dist = null
	var best_tile = null
	for tile in shootable_tiles:
		var dist = target_tile - tile
		var move = dist
		move.x = clamp(move.x, -1, 1)
		move.y = clamp(move.y, -1, 1)
		var shooter_new_tile = obj_tile + move
		var tile_content = Globals.LevelLoaderRef.GetTile(shooter_new_tile)
		var can_use = true
		if obj.get_attrib("type") != "player" and not tile_content.empty():
			for l in tile_content:
				if l != obj and l.get_attrib("type") in ["player", "ship", "anomaly", "planet", "mothership", "drone"]:
					can_use = false
					break
					
		# For AoE weapons this is probably not perfect but it should be close enough
		# I want to avoid adding all the tiles inside the area of effect, I feel it would be too expensive
		# This should return 0 if the player is inside the area of effect which is good
		# not sure about diagonals tough
		var length = max(0.0, dist.length() - area_size)
		if min_length == null or (can_use and min_length > length):
			min_length = length
			best_dist = dist
			best_tile = tile
			
	return [best_dist, best_tile, min_length]
		

func _DoTargetting(player, weapon):
	var scene = Preloader.TargettingReticle
	var player_tile = Globals.LevelLoaderRef.World_to_Tile(player.position)
	var r = get_node("/root/Root/OverlayTiles")
	var n = null
	var fire_radius = weapon.weapon_data.weapon_data.fire_range + Globals.EffectRef.GetBonusValue(player, "", weapon.get("modified_attributes", {}), "range_bonus")
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
			if IsValidTile(fire_radius, obj_tile, tile, weapon):
				n = scene.instance()
				r.call_deferred("add_child", n)
				n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
				n.add_to_group("overlay")
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if IsValidTile(fire_radius, obj_tile, tile, weapon):
					n = scene.instance()
					r.call_deferred("add_child", n)
					n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
					n.add_to_group("overlay")
			if offset.y != 0:
				offset.y *= -1
				tile = obj_tile + offset
				if IsValidTile(fire_radius, obj_tile, tile, weapon):
					n = scene.instance()
					r.call_deferred("add_child", n)
					n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
					n.add_to_group("overlay")
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if offset.y != 0 and IsValidTile(fire_radius, obj_tile, tile, weapon):
					n = scene.instance()
					r.call_deferred("add_child", n)
					n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
					n.add_to_group("overlay")
			offset.y *= -1
			offset.y += 1
		offset.y = 0
		offset.x += 1
		
