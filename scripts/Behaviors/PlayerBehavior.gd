extends Node

export(NodePath) var levelLoaderNode
export(NodePath) var WeaponAction
export(NodePath) var GrabAction
export(NodePath) var InventoryAction
export(NodePath) var InventoryDialog
export(NodePath) var CraftingAction
export(NodePath) var FTLAction
export(NodePath) var PopupButtons
export(NodePath) var TargettingHUD
export(NodePath) var OptionBtn

var playerNode : Node2D = null
var levelLoaderRef : Node
var click_start_pos
var lock_input = false # when it's not player turn, inputs are locked
var next_touch_is_a_goto = false # when camera is dragged, instead of moving in a single direction, a touch will make the ship do pathfinding
var _weapon_shots = []

enum SHOOTING_STATE {
	init,
	wait_targetting,
	wait_damage,
	done
}

enum INPUT_STATE {
	hud,
	weapon_targetting,
	board_targetting,
	loot_targetting,
	look_around,
	test
}
var _input_state = INPUT_STATE.hud

enum PLAYER_ORIGIN {
	wormhole,
	random,
	saved
}
var _current_origin = PLAYER_ORIGIN.saved
var _wormhole_src = null # for positioning the player when he goes up or down

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	levelLoaderRef = get_node(levelLoaderNode)
	
	var action = get_node(WeaponAction)
	action.connect("pressed", self, "Pressed_Weapon_Callback")
	action = get_node(GrabAction)
	action.connect("pressed", self, "Pressed_Grab_Callback")
	action = get_node(InventoryAction)
	action.connect("pressed", self, "Pressed_Inventory_Callback")
	action = get_node(FTLAction)
	action.connect("pressed", self, "Pressed_FTL_Callback")
	action = get_node(CraftingAction)
	action.connect("pressed", self, "Pressed_Crafting_Callback")
	action = get_node(PopupButtons)
	action.connect("mount_pressed", self, "Pressed_Equip_Callback")
	action.connect("look_pressed", self, "Pressed_Look_Callback")
	action.connect("board_pressed", self, "Pressed_Board_Callback")
	action.connect("take_pressed", self, "Pressed_Take_Callback")
	action = get_node(InventoryDialog)
	action.connect("drop_pressed", self, "OnDropIventory_Callback")
	action.connect("use_pressed", self, "OnUseInventory_Callback")
	action = get_node(OptionBtn)
	action.connect("pressed", self, "Pressed_Option_Callback")
	
	get_node(TargettingHUD).connect("cancel_pressed", self, "cancel_targetting_pressed_Callback")
	
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	BehaviorEvents.connect("OnCameraDragged", self, "OnCameraDragged_Callback")
	
func OnCameraDragged_Callback():
	if _input_state == INPUT_STATE.hud:
		next_touch_is_a_goto = true
	
func Pressed_Look_Callback():
	if lock_input:
		return
	_input_state = INPUT_STATE.look_around
	BehaviorEvents.emit_signal("OnLogLine", "Select area to scan...")
	
func Pressed_Equip_Callback():
	if lock_input:
		return
	
	BehaviorEvents.emit_signal("OnPushGUI", "EquipMountList", {"object":playerNode, "callback_object":self, "callback_method":"OnEquip_Callback"})
	
func Pressed_Board_Callback():
	if lock_input:
		return
		
	BehaviorEvents.emit_signal("OnLogLine", "Which ship should we transfer control ?")
	_input_state = INPUT_STATE.board_targetting
	var targetting_data = {"weapon_data":{"fire_range":1, "fire_pattern":"o"}}
	BehaviorEvents.emit_signal("OnRequestTargettingOverlay", playerNode, targetting_data, self, "ProcessBoardSelection")
	BehaviorEvents.emit_signal("OnPopGUI") #HUD
	BehaviorEvents.emit_signal("OnPushGUI", "TargettingHUD", null)

func Pressed_Take_Callback():
	if lock_input:
		return
		
	BehaviorEvents.emit_signal("OnLogLine", "Take from what ?")
	_input_state = INPUT_STATE.loot_targetting
	var targetting_data = {"weapon_data":{"fire_range":1, "fire_pattern":"o"}}
	BehaviorEvents.emit_signal("OnRequestTargettingOverlay", playerNode, targetting_data, self, "ProcessTakeSelection")
	BehaviorEvents.emit_signal("OnPopGUI") #HUD
	BehaviorEvents.emit_signal("OnPushGUI", "TargettingHUD", null)
	
func UpdateButtonVisibility():
	var weapons = playerNode.get_attrib("mounts.weapon")
	var weapon_btn = get_node(WeaponAction)
	var valid = false
	for weapon in weapons:
		if weapon != null and weapon != "":
			valid = true
			break
	if valid == true:
		weapon_btn.visible = true
	else:
		weapon_btn.visible = false
		
	var converters = playerNode.get_attrib("mounts.converter")
	var converter_btn = get_node(CraftingAction)
	valid = false
	for c in converters:
		if c != null and c != "":
			valid = true
			break
	if valid == true:
		converter_btn.visible = true
	else:
		converter_btn.visible = false
	
func OnMountAdded_Callback(obj, mount, src):
	if obj != playerNode:
		return
	UpdateButtonVisibility()

func OnMountRemoved_Callback(obj, mount, src):
	if obj != playerNode:
		return
	UpdateButtonVisibility()
	
# mount_to = "converter"
# mount_item = {"src":"data/json/bleh.json", "count":5}
func OnEquip_Callback(mount_item, mount_to, mount_index):
	BehaviorEvents.emit_signal("OnEquipMount", playerNode, mount_to, mount_index, mount_item)
	
func Pressed_Crafting_Callback():
	if lock_input:
		return
	
	BehaviorEvents.emit_signal("OnPushGUI", "Converter", {"object":playerNode, "callback_object":self, "callback_method":"OnCraft_Callback"})
	
func OnCraft_Callback(recipe_data, input_list):
	var craftingSystem = get_parent().get_node("Crafting")
	var result = craftingSystem.Craft(recipe_data, input_list, playerNode)
	if result == Globals.CRAFT_RESULT.success:
		BehaviorEvents.emit_signal("OnLogLine", "Production sucessful")
	elif result == Globals.CRAFT_RESULT.not_enough_resources:
		BehaviorEvents.emit_signal("OnLogLine", "Missing resources")
	elif result == Globals.CRAFT_RESULT.not_enough_energy:
		BehaviorEvents.emit_signal("OnLogLine", "Not enough energy")
	else:
		BehaviorEvents.emit_signal("OnLogLine", "Crafting failed")
		
	
func Pressed_Grab_Callback():
	if lock_input:
		return
		
	BehaviorEvents.emit_signal("OnPickup", playerNode, Globals.LevelLoaderRef.World_to_Tile(playerNode.position))
	
func Pressed_Inventory_Callback():
	if lock_input:
		return
		
	BehaviorEvents.emit_signal("OnPushGUI", "Inventory", {"object":playerNode})

func Pressed_FTL_Callback():
	var wormholes = Globals.LevelLoaderRef.objByType["wormhole"]
	var wormhole = null
	for w in wormholes:
		if w.position == playerNode.position:
			wormhole = w
			break
	if wormhole == null:
		return
	
	var cur_depth = Globals.LevelLoaderRef.current_depth
	
	_current_origin = PLAYER_ORIGIN.wormhole
	_wormhole_src = Globals.LevelLoaderRef._current_level_data.src
	
	if wormhole.base_attributes != Globals.LevelLoaderRef.GetCurrentLevelData():
		BehaviorEvents.emit_signal("OnRequestLevelChange", wormhole)
	else:
		ProcessGoingHome()
		
func ProcessGoingHome():
	var converter = playerNode.get_attrib("mounts.converter")[0]
	var converter_data = Globals.LevelLoaderRef.LoadJSON(converter)
	if Globals.get_data(converter_data, "end_game") == true:
		BehaviorEvents.emit_signal("OnLogLine", "The Converter of Yendor uses the energy of the wormhole itself to rip a hole trough space. You spool up the engines and glide through it. On the other side HOME is waiting ! You made it !")
		playerNode.set_attrib("game_won", true)
		BehaviorEvents.emit_signal("OnPlayerDeath")
	else:
		var in_cargo = false
		var cargo = playerNode.get_attrib("cargo.content")
		for item in cargo:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			if item.count > 0 and Globals.get_data(data, "end_game") == true:
				in_cargo = true
				break
		if in_cargo == true:
			BehaviorEvents.emit_signal("OnLogLine", "The Converter of Yendor will not work unless it is mounted on the ship !")
		else:
			BehaviorEvents.emit_signal("OnPushGUI", "WelcomeScreen", {"player_name":playerNode.get_attrib("player_name")})

func OnUseInventory_Callback(key):
	var data = Globals.LevelLoaderRef.LoadJSON(key)
	var energy_used = Globals.get_data(data, "consumable.energy")
	var ap_used = Globals.get_data(data, "consumable.ap")
	BehaviorEvents.emit_signal("OnConsumeItem", playerNode, data)
	if ap_used != null and ap_used > 0:
		BehaviorEvents.emit_signal("OnUseAP", playerNode, ap_used)
	if energy_used != null and energy_used > 0:
		BehaviorEvents.emit_signal("OnUseEnergy", playerNode, energy_used)
	BehaviorEvents.emit_signal("OnRemoveItem", playerNode, key)
	

func OnDropIventory_Callback(dropped_mounts, dropped_cargo):
	playerNode.init_mounts()
	for drop_data in dropped_mounts:
		BehaviorEvents.emit_signal("OnDropMount", playerNode, drop_data.key, drop_data.index)
		
	UpdateButtonVisibility()
		
	for drop_data in dropped_cargo:
		BehaviorEvents.emit_signal("OnDropCargo", playerNode, drop_data.src)
	
func OnRequestObjectUnload_Callback(obj):
	if obj.get_attrib("type") == "player":
		playerNode = null
	
func OnObjTurn_Callback(obj):
	# sometimes we put the player on cruise control. when we give him back control "ai" component will be disabled
	if obj.get_attrib("type") == "player" and obj.get_attrib("ai") == null:
		lock_input = false
		
		var moved = obj.get_attrib("moving.moved")
		if  moved == true:
			obj.set_attrib("moving.moved", false)
			var tile_pos = Globals.LevelLoaderRef.World_to_Tile(obj.position)
			var content = Globals.LevelLoaderRef.levelTiles[tile_pos.x][tile_pos.y]
			var filtered = []
			var wormhole = null
			for c in content:
				if c != obj and not c.get_attrib("type") in ["prop"]:
					filtered.push_back(c)
				if c != obj and c.get_attrib("type") in ["wormhole"]:
					wormhole = c
			if filtered.size() == 1:
				BehaviorEvents.emit_signal("OnLogLine", "Ship in range of " + filtered[0].get_attrib("name_id"))
			elif filtered.size() > 1:
				BehaviorEvents.emit_signal("OnLogLine", "Multiple Objects Detected")
			
			var btn = get_node(FTLAction)
			if wormhole != null:
				btn.visible = true
			else:
				btn.visible = false
	else:
		lock_input = true
	
func Pressed_Weapon_Callback():
	if lock_input:
		return
	
	var weapons = playerNode.get_attrib("mounts.weapon")
	var weapons_data = Globals.LevelLoaderRef.LoadJSONArray(weapons)
	if weapons_data == null or weapons_data.size() <= 0:
		BehaviorEvents.emit_signal("OnLogLine", "Mount some weapon first")
		return
		
	_weapon_shots = []
	for data in weapons_data:
		_weapon_shots.push_back({"state":SHOOTING_STATE.init, "weapon_data":data})
		
	var cur_weapon = _weapon_shots[0]
	cur_weapon.state = SHOOTING_STATE.wait_targetting
	BehaviorEvents.emit_signal("OnLogLine", "Firing " + cur_weapon.weapon_data.name_id + ". Target ?")
	BehaviorEvents.emit_signal("OnRequestTargettingOverlay", playerNode, cur_weapon.weapon_data, self, "ProcessAttackSelection")
	BehaviorEvents.emit_signal("OnPopGUI") #HUD
	BehaviorEvents.emit_signal("OnPushGUI", "TargettingHUD", null)
	_input_state = INPUT_STATE.weapon_targetting
	
func OnLevelLoaded_Callback():
	lock_input = false
	if playerNode == null:
		
		var save = Globals.LevelLoaderRef.cur_save
		if save == null or not save.has("player_data"):
			_current_origin = PLAYER_ORIGIN.wormhole
		
		var template = "data/json/ships/player_default.json"
		var level_id = Globals.LevelLoaderRef.GetLevelID()
		var coord
		
		if _current_origin == PLAYER_ORIGIN.random:
			var x = MersenneTwister.rand(Globals.LevelLoaderRef.levelSize.x)
			var y = MersenneTwister.rand(Globals.LevelLoaderRef.levelSize.y)
			coord = Vector2(x, y)
		
		if _current_origin == PLAYER_ORIGIN.saved && save != null && save.has("player_data"):
			#cur_save.player_data["src"] = objByType["player"][0].get_attrib("src")
			#cur_save.player_data["position_x"] = World_to_Tile(objByType["player"][0].position).y
			#cur_save.player_data["position_y"] = World_to_Tile(objByType["player"][0].position).x
			#cur_save.player_data["modified_attributes"] = objByType["player"][0].modified_attributes
			coord = Vector2(save.player_data.position_x, save.player_data.position_y)
		
		var starting_wormhole = null
		if _current_origin == PLAYER_ORIGIN.wormhole:
			
			for w in levelLoaderRef.objByType["wormhole"]:
				var is_src_wormhole = _wormhole_src != null && Globals.clean_path(_wormhole_src) == Globals.clean_path(w.get_attrib("src"))
				var is_top_wormhole = starting_wormhole == null || w.modified_attributes["depth"] < starting_wormhole.modified_attributes["depth"]
				if (_wormhole_src == null && is_top_wormhole) || (is_src_wormhole):
					starting_wormhole = w
			
			coord = levelLoaderRef.World_to_Tile(starting_wormhole.position)
			
		#TODO: Pop menu for player creation ?
		var modififed_attrib = null
		if save != null && save.has("player_data"):
			modififed_attrib = save.player_data.modified_attributes
			template = save.player_data.src
		# Modified_attrib must be passed during request so that proper IDs can be locked in objByID
		playerNode = levelLoaderRef.RequestObject(template, coord, modififed_attrib)
		if playerNode.get_attrib("player_name") == null:
			playerNode.set_attrib("player_name", PermSave.get_attrib("settings.default_name", "Ombarus"))
		
		BehaviorEvents.emit_signal("OnPlayerCreated", playerNode)
		
		UpdateButtonVisibility()
		
		# always default to saved position
		_current_origin = PLAYER_ORIGIN.saved
	
func _input(event):
	if _input_state != INPUT_STATE.look_around or not event is InputEventMouseButton:
		return
		
	if click_start_pos == null:
			click_start_pos = Vector2(0,0)
	if event.is_action_pressed("touch"):
		click_start_pos = event.position
	var vp_size : Vector2 = get_viewport().size
	var drag_vec : Vector2 = click_start_pos - event.position
	var per_drag_x : float = abs(drag_vec.x / vp_size.x)
	var per_drag_y : float = abs(drag_vec.y / vp_size.y)
	
	if not event.is_action_released("touch") or per_drag_x > 0.04 or per_drag_y > 0.04:
		return
	
	click_start_pos = Vector2(0,0)
	_input_state = INPUT_STATE.hud
	#get_tree().set_input_as_handled()
	
	var click_pos = playerNode.get_global_mouse_position()
	
	var tile = Globals.LevelLoaderRef.World_to_Tile(click_pos)
	var tile_content = Globals.LevelLoaderRef.levelTiles[tile.x][tile.y]
	var str_fmt = "There is %s here"
	var filtered_content = []
	for obj in tile_content:
		if obj.visible == true and obj.get_attrib("has_ghost_memory") == null:
			filtered_content.push_back(obj)
	if filtered_content.size() == 0:
		BehaviorEvents.emit_signal("OnLogLine", "Nothing but empty space")
	for obj in filtered_content:
		BehaviorEvents.emit_signal("OnLogLine", str_fmt % obj.get_attrib("name_id"))
	

func _unhandled_input(event):
	if lock_input or _input_state == INPUT_STATE.look_around:
		return
		
	var dir = null
	
	if event is InputEventMouseButton:
		if click_start_pos == null:
			click_start_pos = Vector2(0,0)
		var vp_size = get_viewport().size
		var drag_vec = click_start_pos - event.position
		var per_drag_x = abs(drag_vec.x / vp_size.x)
		var per_drag_y = abs(drag_vec.y / vp_size.y)
		if event.is_action_pressed("touch"):
			click_start_pos = event.position
		elif event.is_action_released("touch") && per_drag_x < 0.04 && per_drag_y < 0.04:
			var click_pos = playerNode.get_global_mouse_position()
			
			if _input_state == INPUT_STATE.weapon_targetting:
				_input_state = INPUT_STATE.hud
				BehaviorEvents.emit_signal("OnTargetClick", click_pos, Globals.VALID_TARGET.attack)
			elif _input_state == INPUT_STATE.board_targetting:
				_input_state = INPUT_STATE.hud
				BehaviorEvents.emit_signal("OnTargetClick", click_pos, Globals.VALID_TARGET.board)
			elif _input_state == INPUT_STATE.loot_targetting:
				_input_state = INPUT_STATE.hud
				BehaviorEvents.emit_signal("OnTargetClick", click_pos, Globals.VALID_TARGET.loot)
			elif _input_state == INPUT_STATE.test:
				DO_TEST(click_pos)
			else:
				var player_pos = playerNode.position
				var clicked_tile = Globals.LevelLoaderRef.World_to_Tile(click_pos)
				var player_tile = Globals.LevelLoaderRef.World_to_Tile(player_pos)
				
				if next_touch_is_a_goto == true and clicked_tile == player_tile:
					next_touch_is_a_goto = false
				
				if next_touch_is_a_goto == true:
					var ai_data = {
						"aggressive":false,
						"pathfinding":"simple",
						"disable_on_interest":true,
						"disable_wandering":true,
						"objective":clicked_tile
					}
					playerNode.set_attrib("ai", ai_data)
					BehaviorEvents.emit_signal("OnAttributeAdded", playerNode, "ai")
					next_touch_is_a_goto = false
					return # not the best middle of function return I've ever done....
					
				var click_dir = click_pos - player_pos
				var rot = rad2deg(Vector2(0.0, 0.0).angle_to_point(click_dir)) - 90.0
				if rot < 0:
					rot += 360
					
				var did_other_action : bool = do_contextual_actions(clicked_tile, player_tile)
				if did_other_action == true:
					return
				
				# Calculate direction based on touch relative to player position.
				# dead zone (click on sprite)
				if abs(click_dir.x) < levelLoaderRef.tileSize / 2 && abs(click_dir.y) < levelLoaderRef.tileSize / 2:
					BehaviorEvents.emit_signal("OnUseAP", playerNode, 1.0)
					BehaviorEvents.emit_signal("OnLogLine", "Cooling reactor (wait)")
					dir = null
				elif rot > 337.5 || rot <= 22.5:
					dir = Vector2(0,-1) # 8
				elif rot > 22.5 && rot <= 67.5:
					dir = Vector2(1,-1) # 9
				elif rot > 67.5 && rot <= 112.5:
					dir = Vector2(1,0) # 6
				elif rot > 112.5 && rot <= 157.5:
					dir = Vector2(1,1) # 3
				elif rot > 157.5 && rot <= 202.5:
					dir = Vector2(0,1) # 2
				elif rot > 202.5 && rot <= 247.5:
					dir = Vector2(-1,1) # 1
				elif rot > 247.5 && rot <= 292.5:
					dir = Vector2(-1,0) # 4
				elif rot > 292.5 && rot <= 337.5:
					dir = Vector2(-1,-1) # 7
				
	if event is InputEventKey && event.pressed == false:
		if event.scancode == KEY_KP_1:
			dir = Vector2(-1,1)
		if event.scancode == KEY_KP_2:
			dir = Vector2(0,1)
		if event.scancode == KEY_KP_3:
			dir = Vector2(1,1)
		if event.scancode == KEY_KP_4:
			dir = Vector2(-1,0)
		if event.scancode == KEY_KP_6:
			dir = Vector2(1,0)
		if event.scancode == KEY_KP_7:
			dir = Vector2(-1,-1)
		if event.scancode == KEY_KP_8:
			dir = Vector2(0,-1)
		if event.scancode == KEY_KP_9:
			dir = Vector2(1,-1)
		if event.scancode == KEY_KP_5:
			BehaviorEvents.emit_signal("OnUseAP", playerNode, 1.0)
			BehaviorEvents.emit_signal("OnLogLine", "Cooling reactor (wait)")
		if event.scancode == KEY_M:
			Pressed_Equip_Callback()
		if event.scancode == KEY_L:
			Pressed_Look_Callback()
		if event.scancode == KEY_B:
			Pressed_Board_Callback()
		if event.scancode == KEY_T:
			Pressed_Take_Callback()
		
		# GODOT cannot give me the real key that was pressed. Only the physical key
		# in En-US keyboard layout. There's no way to register a shortcut that's on a modifier (like !@#$%^&*())
		#TODO: Stay updated on this issue on their git tracker. This is serious enough to make me want to change engine
		#		On the other end. Being open-source I could probably hack something if it becomes too big an issue
		#		Check out : Godot_src\godot\scene\gui\text_edit.cpp for how they handle acutal text in input forms
		#		Check out : Godot_src\godot\core\os\input_event.cpp for how shortcut key inputs are handled
		if (event.scancode == KEY_PERIOD || event.scancode == KEY_COLON) && event.shift == true:
			Pressed_FTL_Callback()
		#print(event.scancode)
		#print ("key_period : ", KEY_PERIOD, ", key_comma : ", KEY_COLON)
	if dir != null:
		next_touch_is_a_goto = false
		BehaviorEvents.emit_signal("OnMovement", playerNode, dir)


func do_contextual_actions(tile, player_tile):
	var content : Array = Globals.LevelLoaderRef.GetTile(tile)
	var dist = (tile - player_tile).length()
	for o in content:
		if o == playerNode or o.visible == false or o.get_attrib("ghost_memory") != null:
			continue
			
		if o.get_attrib("equipment") != null and tile == player_tile:
			Pressed_Grab_Callback()
			return true
			
		if o.get_attrib("type") == "wormhole" and tile == player_tile:
			Pressed_FTL_Callback()
			return true
			
		if Globals.is_(o.get_attrib("cargo.transferable"), true) and dist < 2.0:
			Pressed_Take_Callback()
			return true
			
		if o.get_attrib("destroyable") != null || o.get_attrib("harvestable") != null:
			var targetting_behavior : Node = get_node("../Targetting")
			
			var weapons = playerNode.get_attrib("mounts.weapon")
			var weapons_data = Globals.LevelLoaderRef.LoadJSONArray(weapons)
			if weapons_data != null and weapons_data.size() > 0:
				for w in weapons_data:
					var best_move = targetting_behavior.ClosestFiringSolution(player_tile, tile, w)
					if best_move.length() == 0:
						Pressed_Weapon_Callback()
						return true
		#TODO: If more  than one possible contextual action maybe pop a menu ?
		#elif o.get_attrib("boardable") == true:
		#	return true
			
	return false

func cancel_targetting_pressed_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "HUD", null)
	_input_state = INPUT_STATE.hud
	

#TODO: if target is out-of-range the sequence will be aborted. Should probably fix that if you have more than one weapon
func ProcessAttackSelection(target):
	_input_state = INPUT_STATE.hud
	var cur_weapon = null
	for shot in _weapon_shots:
		if shot.state == SHOOTING_STATE.wait_damage:
			continue
		elif shot.state == SHOOTING_STATE.wait_targetting:
			shot["target"] = target
			shot.state = SHOOTING_STATE.wait_damage
		elif shot.state == SHOOTING_STATE.init and cur_weapon == null:
			cur_weapon = shot
	
	if cur_weapon != null:
		cur_weapon.state = SHOOTING_STATE.wait_targetting
		BehaviorEvents.emit_signal("OnLogLine", "Acknowledged, should we also fire " + cur_weapon.weapon_data.name_id + ". Target ?")
		BehaviorEvents.emit_signal("OnRequestTargettingOverlay", playerNode, cur_weapon.weapon_data, self, "ProcessAttackSelection")
		_input_state = INPUT_STATE.weapon_targetting
		return
	
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "HUD", null)
	
	var all_canceled = true
	for shot in _weapon_shots:
		if "target" in shot and shot.target != null:
			all_canceled = false
			break
			
	if all_canceled == true:
		BehaviorEvents.emit_signal("OnLogLine", "There's nothing there sir...")
		return
	
	BehaviorEvents.emit_signal("OnBeginParallelAction", playerNode)
	for shot in _weapon_shots:
		if shot.target != null:
			var destroyed_state = shot.target.get_attrib("destroyable.destroyed")
			if destroyed_state == null or destroyed_state == false:
				BehaviorEvents.emit_signal("OnDealDamage", shot.target, playerNode, shot.weapon_data)
	BehaviorEvents.emit_signal("OnEndParallelAction", playerNode)
	
func ProcessBoardSelection(target):
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "HUD", null)
	_input_state = INPUT_STATE.hud
	if target != null:
		var pnode = playerNode
		BehaviorEvents.emit_signal("OnTransferPlayer", pnode, target)
	else:
		BehaviorEvents.emit_signal("OnLogLine", "Ship transfer canceled")
	
func ProcessTakeSelection(target):
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "HUD", null)
	_input_state = INPUT_STATE.hud
	if target == null:
		BehaviorEvents.emit_signal("OnLogLine", "Item transfer canceled")
		return
		
	BehaviorEvents.emit_signal("OnPushGUI", "TransferInventory", {"object1":playerNode, "object2":target, "callback_object":self, "callback_method":"OnTransferItemCompleted_Callback"})
	
func OnTransferItemCompleted_Callback(lobj, l_mounts, l_cargo, robj, r_mounts, r_cargo):
	lobj.init_mounts()
	lobj.init_cargo()
	robj.init_mounts()
	robj.init_cargo()
	
	BehaviorEvents.emit_signal("OnReplaceMounts", lobj, l_mounts)
	BehaviorEvents.emit_signal("OnReplaceMounts", robj, r_mounts)
	
	BehaviorEvents.emit_signal("OnClearCargo", lobj)
	BehaviorEvents.emit_signal("OnClearCargo", robj)
	for item in l_cargo:
		#TODO: optimize, allow passing how many
		for i in range(item.amount):
			BehaviorEvents.emit_signal("OnAddItem", lobj, item.src_key)
	
	for item in r_cargo:
		for i in range(item.amount):
			BehaviorEvents.emit_signal("OnAddItem", robj, item.src_key)
	
	#TODO: Should the AP use sum the total # of item moved and equip/unequip ap ? (probably ?)
	if lobj.get_attrib("cargo.pickup_ap") != null:
		BehaviorEvents.emit_signal("OnUseAP", lobj, lobj.get_attrib("cargo.pickup_ap"))
	
func OnTransferPlayer_Callback(old_player, new_player):
	playerNode = new_player
	BehaviorEvents.emit_signal("OnLogLine", "All controls transfered, the ship is ours captain !")
	BehaviorEvents.emit_signal("OnUseAP", new_player, 1.0)

	UpdateButtonVisibility()
		
		
	new_player.set_attrib("moving.moved", true) # to update the wormhole button in next "OnPlayerTurn"
	
func DO_TEST(click_pos):
	pass


func Pressed_Option_Callback():
	BehaviorEvents.emit_signal("OnPushGUI", "Options", {})
