extends Node

export(NodePath) var levelLoaderNode
export(NodePath) var WeaponAction
export(NodePath) var GrabAction
export(NodePath) var DropAction
export(NodePath) var CraftingAction
export(NodePath) var FTLAction
export(NodePath) var PopupButtons

var playerNode = null
var levelLoaderRef
var click_start_pos
var lock_input = false # when it's not player turn, inputs are locked

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
	action = get_node(DropAction)
	action.connect("pressed", self, "Pressed_Drop_Callback")
	action = get_node(FTLAction)
	action.connect("pressed", self, "Pressed_FTL_Callback")
	action = get_node(CraftingAction)
	action.connect("pressed", self, "Pressed_Crafting_Callback")
	action = get_node(PopupButtons)
	action.connect("mount_pressed", self, "Pressed_Equip_Callback")
	action.connect("look_pressed", self, "Pressed_Look_Callback")
	action.connect("board_pressed", self, "Pressed_Board_Callback")
	action.connect("take_pressed", self, "Pressed_Take_Callback")
	
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	
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

func Pressed_Take_Callback():
	if lock_input:
		return
		
	BehaviorEvents.emit_signal("OnLogLine", "Take from what ?")
	_input_state = INPUT_STATE.loot_targetting
	var targetting_data = {"weapon_data":{"fire_range":1, "fire_pattern":"o"}}
	BehaviorEvents.emit_signal("OnRequestTargettingOverlay", playerNode, targetting_data, self, "ProcessTakeSelection")
	
func OnMountAdded_Callback(obj, mount, src):
	if obj != playerNode:
		return
	if "converter" in mount:
		var converter_btn = get_node(CraftingAction)
		if src == null or src == "":
			converter_btn.visible = false
		else:
			converter_btn.visible = true
	if "weapon" in mount:
		var weapon_btn = get_node(WeaponAction)
		if src == null or src == "":
			weapon_btn.visible = false
		else:
			weapon_btn.visible = true

func OnMountRemoved_Callback(obj, mount, src):
	if obj != playerNode:
		return
	if "converter" in mount:
		var converter_btn = get_node(CraftingAction)
		converter_btn.visible = false
	if "weapon" in mount:
		var weapon_btn = get_node(WeaponAction)
		weapon_btn.visible = false
	
# mount_to = "converter"
# mount_item = {"src":"data/json/bleh.json", "count":5}
func OnEquip_Callback(mount_item, mount_to):
	BehaviorEvents.emit_signal("OnEquipMount", playerNode, mount_to, mount_item)
	
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
	
func Pressed_Drop_Callback():
	if lock_input:
		return
		
	BehaviorEvents.emit_signal("OnPushGUI", "Inventory", {"object":playerNode, "callback_object":self, "callback_method":"OnDropIventory_Callback"})

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
		
	BehaviorEvents.emit_signal("OnRequestLevelChange", wormhole)

func OnDropIventory_Callback(dropped_mounts, dropped_cargo):
	playerNode.init_mounts()
	for drop_data in dropped_mounts:
		BehaviorEvents.emit_signal("OnDropMount", playerNode, drop_data.key, drop_data.index)
		
	var converter = playerNode.get_attrib("mounts.converter")[0]
	var converter_btn = get_node(CraftingAction)
	if converter == null or converter == "":
		converter_btn.visible = false
	else:
		converter_btn.visible = true
		
	for drop_data in dropped_cargo:
		BehaviorEvents.emit_signal("OnDropCargo", playerNode, drop_data.src)
	
func OnRequestObjectUnload_Callback(obj):
	if obj.get_attrib("type") == "player":
		playerNode = null
	
func OnObjTurn_Callback(obj):
	if obj.get_attrib("type") == "player":
		print("On Player Turn : Unlock Input")
		lock_input = false
		
		var moved = obj.get_attrib("moving.moved")
		if  moved == true:
			obj.set_attrib("moving.moved", false)
			var tile_pos = Globals.LevelLoaderRef.World_to_Tile(obj.position)
			var content = Globals.LevelLoaderRef.levelTiles[tile_pos.x][tile_pos.y]
			var filtered = []
			var wormhole = null
			for c in content:
				if c != obj and not c.base_attributes.type in ["prop"]:
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
		print("On AI Turn : LOCK Input !")
		lock_input = true
	
func Pressed_Weapon_Callback():
	if lock_input:
		return
	
	var weapon_json = playerNode.get_attrib("mounts.small_weapon_mount")
	if weapon_json == null or weapon_json.empty() == true:
		BehaviorEvents.emit_signal("OnLogLine", "Mount some weapon first")
		return
		
	BehaviorEvents.emit_signal("OnLogLine", "Weapon System Online. Target ?")
	var weapon_data = Globals.LevelLoaderRef.LoadJSON(weapon_json)
	BehaviorEvents.emit_signal("OnRequestTargettingOverlay", playerNode, weapon_data, self, "ProcessAttackSelection")
	_input_state = INPUT_STATE.weapon_targetting
	
func OnLevelLoaded_Callback():
	print("OnLevelLoaded : unlock input")
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
			template = save.player_data.src
			coord = Vector2(save.player_data.position_x, save.player_data.position_y)
		
		var starting_wormhole = null
		if _current_origin == PLAYER_ORIGIN.wormhole:
			
			for w in levelLoaderRef.objByType["wormhole"]:
				var is_src_wormhole = _wormhole_src != null && _wormhole_src == w.get_attrib("src")
				var is_top_wormhole = starting_wormhole == null || w.modified_attributes["depth"] < starting_wormhole.modified_attributes["depth"]
				if (_wormhole_src == null && is_top_wormhole) || (is_src_wormhole):
					starting_wormhole = w
			
			coord = levelLoaderRef.World_to_Tile(starting_wormhole.position)
			
		#TODO: Pop menu for player creation ?
		var modififed_attrib = null
		if save != null && save.has("player_data"):
			modififed_attrib = save.player_data.modified_attributes
		# Modified_attrib must be passed during request so that proper IDs can be locked in objByID
		playerNode = levelLoaderRef.RequestObject("data/json/ships/player_default.json", coord, modififed_attrib)
		
		var converter = playerNode.get_attrib("mounts.converter")[0]
		var converter_btn = get_node(CraftingAction)
		if converter == null or converter == "":
			converter_btn.visible = false
		else:
			converter_btn.visible = true
		
		# always default to saved position
		_current_origin = PLAYER_ORIGIN.saved
	
func _input(event):
	if _input_state != INPUT_STATE.look_around or not event is InputEventMouseButton or not event.is_action_released("touch"):
		return
		
	_input_state = INPUT_STATE.hud
	get_tree().set_input_as_handled()
	
	var click_pos = playerNode.get_global_mouse_position()
	
	var tile = Globals.LevelLoaderRef.World_to_Tile(click_pos)
	var tile_content = Globals.LevelLoaderRef.levelTiles[tile.x][tile.y]
	var str_fmt = "There is %s here"
	if tile_content.size() == 0:
		BehaviorEvents.emit_signal("OnLogLine", "Nothing but empty space")
	for obj in tile_content:
		BehaviorEvents.emit_signal("OnLogLine", str_fmt % obj.get_attrib("name_id"))
	

func _unhandled_input(event):
	if lock_input:
		return
		
	var dir = null
	if event is InputEventMouseButton:
		if event.is_action_pressed("touch"):
			click_start_pos = event.position
		elif event.is_action_released("touch") && (click_start_pos - event.position).length_squared() < 5.0:
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
				var click_dir = click_pos - player_pos
				var rot = rad2deg(Vector2(0.0, 0.0).angle_to_point(click_dir)) - 90.0
				if rot < 0:
					rot += 360
				print("player_pos ", player_pos, ", click_pos ", click_pos, ", rot ", rot)
				
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
		BehaviorEvents.emit_signal("OnMovement", playerNode, dir)


func ProcessAttackSelection(target):
	if target == null:
		BehaviorEvents.emit_signal("OnLogLine", "There's nothing there sir...")
		return
		
	var weapon_json = playerNode.get_attrib("mounts.small_weapon_mount")
	var weapon_data = Globals.LevelLoaderRef.LoadJSON(weapon_json)
	BehaviorEvents.emit_signal("OnDealDamage", target, playerNode, weapon_data)
	
func ProcessBoardSelection(target):
	if target != null:
		var pnode = playerNode
		BehaviorEvents.emit_signal("OnTransferPlayer", pnode, target)
	else:
		BehaviorEvents.emit_signal("OnLogLine", "Ship transfer canceled")
	
func ProcessTakeSelection(target):
	if target == null:
		BehaviorEvents.emit_signal("OnLogLine", "Item transfer canceled")
		return
		
	BehaviorEvents.emit_signal("OnPushGUI", "TransferInventory", {"object1":playerNode, "object2":target, "callback_object":self, "callback_method":"OnTransferItemCompleted_Callback"})
	
func OnTransferItemCompleted_Callback(lobj, l_mounts, l_cargo, robj, r_mounts, r_cargo):
	lobj.init_mounts()
	lobj.init_cargo()
	robj.init_mounts()
	robj.init_cargo()
	
	BehaviorEvents.emit_signal("OnClearMounts", lobj)
	BehaviorEvents.emit_signal("OnClearMounts", robj)
	for item in l_mounts:
		BehaviorEvents.emit_signal("OnEquipMount", lobj, item.mount_key, item.mount_index, item.src_key)
	for item in r_mounts:
		BehaviorEvents.emit_signal("OnEquipMount", robj, item.mount_key, item.mount_index, item.src_key)
	
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

	var converter = new_player.get_attrib("mounts.converter")[0]
	var converter_btn = get_node(CraftingAction)
	if converter == null or converter == "":
		converter_btn.visible = false
	else:
		converter_btn.visible = true
		
	new_player.set_attrib("moving.moved", true) # to update the wormhole button in next "OnPlayerTurn"
	
func DO_TEST(click_pos):
	pass
