extends Node

export(NodePath) var levelLoaderNode
export(NodePath) var InventoryDialog
export(NodePath) var TargettingHUD


var weapon_btn_ref = null
var conv_btn_ref = null
var ftl_btn_ref_1 = null
var comm_btn_ref = null


var playerNode : Node2D = null
var levelLoaderRef : Node
var click_start_pos
var click_start_time
var lock_input = false # when it's not player turn, inputs are locked
var _weapon_shots = []
var _last_unicode = ""
var _double_tap_timer : float = 0
var _double_tap_action = ""
var _double_tap_tile

enum SHOOTING_STATE {
	init,
	wait_targetting,
	wait_damage,
	done
}

var _input_state = Globals.INPUT_STATE.hud setget set_input_state
var _saved_input_state = Globals.INPUT_STATE.hud

func set_input_state(newval):
	_input_state = newval
	BehaviorEvents.emit_signal("OnPlayerInputStateChanged", playerNode, newval)

enum PLAYER_ORIGIN {
	wormhole,
	random,
	saved
}
var _current_origin = PLAYER_ORIGIN.saved
var _wormhole_src = null # for positioning the player when he goes up or down

func _ready():
	OS.set_ime_active(true)
	
	var lang = PermSave.get_attrib("settings.lang")
	if lang != null and TranslationServer.get_locale() != lang:
		TranslationServer.set_locale(lang)
		BehaviorEvents.emit_signal("OnLocaleChanged")
		
	# Called when the node is added to the scene for the first time.
	# Initialization here
	levelLoaderRef = get_node(levelLoaderNode)
	
	BehaviorEvents.connect("OnButtonReady", self, "OnButtonReady_Callback")
	
	BehaviorEvents.connect("OnHUDWeaponPressed", self, "Pressed_Weapon_Callback")
	BehaviorEvents.connect("OnHUDGrabPressed", self, "Pressed_Grab_Callback")
	BehaviorEvents.connect("OnHUDInventoryPressed", self, "Pressed_Inventory_Callback")
	BehaviorEvents.connect("OnHUDFTLPressed", self, "Pressed_FTL_Callback")
	BehaviorEvents.connect("OnHUDCraftingPressed", self, "Pressed_Crafting_Callback")
	BehaviorEvents.connect("OnHUDLookPressed", self, "Pressed_Look_Callback")
	BehaviorEvents.connect("OnHUDBoardPressed", self, "Pressed_Board_Callback")
	BehaviorEvents.connect("OnHUDTakePressed", self, "Pressed_Take_Callback")
	BehaviorEvents.connect("OnHUDWaitPressed", self, "Pressed_Wait_Callback")
	BehaviorEvents.connect("OnHUDCrewPressed", self, "Pressed_Crew_Callback")
	BehaviorEvents.connect("OnHUDCommPressed", self, "Pressed_Comm_Callback")
	BehaviorEvents.connect("OnHUDOptionPressed", self, "Pressed_Option_Callback")
	BehaviorEvents.connect("OnHUDQuestionPressed", self, "Pressed_Question_Callback")
	BehaviorEvents.connect("OnPlayerDeath", self, "OnPlayerDeath_Callback")
	BehaviorEvents.connect("OnResumeAttack", self, "OnResumeAttack_Callback")
	BehaviorEvents.connect("OnSystemDisabled", self, "OnSystemDisabled_Callback")
	BehaviorEvents.connect("OnSystemEnabled", self, "OnSystemEnabled_Callback")
	
	var action = get_node(InventoryDialog)
	action.connect("drop_pressed", self, "OnDropIventory_Callback")
	action.connect("use_pressed", self, "OnUseInventory_Callback")
	
	get_node(TargettingHUD).connect("cancel_pressed", self, "cancel_targetting_pressed_Callback")
	
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnRequestObjectUnload", self, "OnRequestObjectUnload_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	BehaviorEvents.connect("OnMountAdded", self, "OnMountAdded_Callback")
	BehaviorEvents.connect("OnMountRemoved", self, "OnMountRemoved_Callback")
	BehaviorEvents.connect("OnAPUsed", self, "OnAPUsed_Callback")
	BehaviorEvents.connect("OnDifficultyChanged", self, "OnDifficultyChanged_Callback")
	BehaviorEvents.connect("OnCameraDragged", self, "OnCameraDragged_Callback")
	

func OnSystemDisabled_Callback(obj, system):
	if obj != playerNode:
		return
	
	UpdateButtonVisibility()
	
func OnSystemEnabled_Callback(obj, system):
	if obj != playerNode:
		return
	
	UpdateButtonVisibility()

func OnPlayerDeath_Callback(player):
	lock_input = true
	
func OnButtonReady_Callback(btn):
	var btn_name = btn.name
	if btn_name == "Weapon":
		weapon_btn_ref = btn
	elif btn_name == "Wormhole":
		ftl_btn_ref_1 = btn
	elif btn_name == "Converter":
		conv_btn_ref = btn
	elif btn_name == "Comm":
		comm_btn_ref = btn
	
func OnDifficultyChanged_Callback(new_diff):
	if playerNode == null:
		return
		
	if Globals.total_turn == 0:
		playerNode.set_attrib("lowest_diff", new_diff)
	else:
		var cur_diff = playerNode.get_attrib("lowest_diff")
		playerNode.set_attrib("lowest_diff", min(cur_diff, new_diff))
	
func OnAPUsed_Callback(obj, amount):
	if obj != playerNode:
		return
	
	lock_input = true
	
func Pressed_Look_Callback():
	if lock_input:
		return
	set_input_state(Globals.INPUT_STATE.look_around)
	
	BehaviorEvents.emit_signal("OnPopGUI") #HUD
	var text = "[color=lime]%s[/color]" % [Globals.mytr("Select area to scan...")]
	BehaviorEvents.emit_signal("OnPushGUI", "TargettingHUD", {"info_text":text, "show_skip":false})
	
	#BehaviorEvents.emit_signal("OnLogLine", "Select area to scan...")

func Pressed_Board_Callback():
	if lock_input:
		return
		
	BehaviorEvents.emit_signal("OnLogLine", "Which ship should we transfer control ?")
	set_input_state(Globals.INPUT_STATE.board_targetting)
	var targetting_data = {"weapon_data":{"weapon_data":{"fire_range":1, "fire_pattern":"o"}}}
	BehaviorEvents.emit_signal("OnRequestTargettingOverlay", playerNode, targetting_data, self, "ProcessBoardSelection")
	BehaviorEvents.emit_signal("OnPopGUI") #HUD
	var text = Globals.mytr("[color=red]Select a ship to board...[/color]")
	BehaviorEvents.emit_signal("OnPushGUI", "TargettingHUD", {"info_text":text, "show_skip":false})

func Pressed_Take_Callback():
	if lock_input:
		return
		
	BehaviorEvents.emit_signal("OnLogLine", "Take from what ?")
	set_input_state(Globals.INPUT_STATE.loot_targetting)
	var targetting_data = {"weapon_data":{"weapon_data":{"fire_range":1, "fire_pattern":"o"}}}
	BehaviorEvents.emit_signal("OnRequestTargettingOverlay", playerNode, targetting_data, self, "ProcessTakeSelection")
	BehaviorEvents.emit_signal("OnPopGUI") #HUD
	var text = Globals.mytr("[color=red]Select a ship to transfer content...[/color]")
	BehaviorEvents.emit_signal("OnPushGUI", "TargettingHUD", {"info_text":text, "show_skip":false})
	
func Pressed_Wait_Callback():
	if lock_input:
		return
		
	wait_one_turn(playerNode)
	
func wait_one_turn(player):
	BehaviorEvents.emit_signal("OnUseAP", playerNode, 1.0)
	var wait_lines = {
		"Cooling reactor (wait)":50,
		"Wasted fuel (wait)":20,
		"Some R&R increased the crew's morale (wait)":5,
		"All system green (wait)":50,
		"System reboot complete (wait)":30,
		"Powering down (wait)":50,
		"Awaiting next order (wait)":50,
		"Network purged (wait)":50
	}
	BehaviorEvents.emit_signal("OnLogLine", wait_lines)
	
func Pressed_Crew_Callback():
	if lock_input:
		return
	
	var runes = playerNode.get_attrib("runes").values()

	BehaviorEvents.emit_signal("OnPushGUI", "Crew", {"crew": runes})
	
func Pressed_Comm_Callback():
	if lock_input:
		return
	
	var tile_pos = Globals.LevelLoaderRef.World_to_Tile(playerNode.position)
	var content = Globals.LevelLoaderRef.levelTiles[tile_pos.x][tile_pos.y]
	var filtered = []
	var trade_port = null
	for c in content:
		if c != playerNode and c.get_attrib("type") in ["trade_port"]:
			trade_port = c
			break
	
	if trade_port != null:
		var id = trade_port.get_attrib("host")
		var target = Globals.LevelLoaderRef.GetObjectById(id)
		BehaviorEvents.emit_signal("OnPushGUI", "Trading", {"object1":playerNode, "object2":target})
	
func UpdateButtonVisibility():
	var hide_hud = PermSave.get_attrib("settings.hide_hud")
	var weapons = playerNode.get_attrib("mounts.weapon", [])
	var weapon_btn = weapon_btn_ref
	var valid = false
	for weapon in weapons:
		if weapon != null and weapon != "":
			valid = true
			break
	valid = valid and not hide_hud
	weapon_btn.Disabled = not valid
		
	var converters = playerNode.get_attrib("mounts.converter")
	var converter_btn = conv_btn_ref
	valid = false
	for c in converters:
		if c != null and c != "":
			valid = true
			break
	valid = valid and not hide_hud
	valid = valid and playerNode.get_attrib("offline_systems.converter", 0.0) <= 0.0
	converter_btn.Disabled = not valid

	
func OnMountAdded_Callback(obj, mount, src, modified_attributes):
	if obj != playerNode:
		return
	UpdateButtonVisibility()

func OnMountRemoved_Callback(obj, mount, src, modified_attributes):
	if obj != playerNode:
		return
	UpdateButtonVisibility()

func Pressed_Crafting_Callback():
	if lock_input:
		return
	
	var converter = playerNode.get_attrib("mounts.converter")
	if converter == null or converter.size() <= 0 or converter[0].empty():
		BehaviorEvents.emit_signal("OnLogLine", "The ship cannot function without a converter installed!")
		return
		
	if playerNode.get_attrib("offline_systems.converter", 0.0) > 0.0:
		BehaviorEvents.emit_signal("OnLogLine", "Our converter has been disabled by the enemy!")
		return
		
	#BehaviorEvents.emit_signal("OnPushGUI", "Converter", {"object":playerNode, "callback_object":self, "callback_method":"OnCraft_Callback"})
	BehaviorEvents.emit_signal("OnPushGUI", "ConverterV2", {"object":playerNode, "callback_object":self, "callback_method":"OnCraft_Callback"})
	
func OnCraft_Callback(recipe_data, input_list):
	var craftingSystem = get_parent().get_node("Crafting")
	var result = craftingSystem.Craft(recipe_data, input_list, playerNode)
	if result == Globals.CRAFT_RESULT.success:
		BehaviorEvents.emit_signal("OnLogLine", "Production sucessful")
		if Globals.get_data(recipe_data, "close_gui", false) == true:
			get_node("../../Camera-GUI/SafeArea/ConverterRoot/ConverterV2").Close_Callback()
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
		
	#BehaviorEvents.emit_signal("OnPushGUI", "Inventory", {"object":playerNode})
	BehaviorEvents.emit_signal("OnPushGUI", "InventoryV2", {"object":playerNode})

func Pressed_FTL_Callback():
	if lock_input:
		return
		
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
	
	var cur_lvl : Dictionary = Globals.LevelLoaderRef.GetCurrentLevelData()
	if wormhole.get_attrib("going_home") == true and "going_home" in cur_lvl and cur_lvl["going_home"] == true:
		ProcessGoingHome()
	else:
		BehaviorEvents.emit_signal("OnRequestLevelChange", wormhole)
		
func ProcessGoingHome():
	var converter = playerNode.get_attrib("mounts.converter")[0]
	var converter_data = null
	if converter != null and converter != "":
		converter_data = Globals.LevelLoaderRef.LoadJSON(converter)
	if converter_data != null and Globals.get_data(converter_data, "end_game") == true:
		BehaviorEvents.emit_signal("OnLogLine", "The Converter of Yendor uses the energy of the wormhole itself to rip a hole trough space. You spool up the engines and glide through it. On the other side HOME is waiting ! You made it !")
		playerNode.set_attrib("game_won", true)
		BehaviorEvents.emit_signal("OnPlayerDeath", playerNode)
	else:
		var in_cargo = false
		var cargo = playerNode.get_attrib("cargo.content", playerNode)
		for item in cargo:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			if item.count > 0 and Globals.get_data(data, "end_game") == true:
				in_cargo = true
				break
		if in_cargo == true:
			BehaviorEvents.emit_signal("OnLogLine", "The Converter of Yendor will not work unless it is mounted on the ship !")
		else:
			BehaviorEvents.emit_signal("OnPushGUI", "WelcomeScreen", {"player_name":playerNode.get_attrib("player_name")})
			BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]This wormhole emits a strange energy signature that prevents you from jumping back home![/color]")

func OnUseInventory_Callback(key, attrib):
	var data = Globals.LevelLoaderRef.LoadJSON(key)
	BehaviorEvents.emit_signal("OnConsumeItem", playerNode, data, key, attrib)
	

func OnDropIventory_Callback(dropped_mounts, dropped_cargo):
	playerNode.init_mounts()
	for drop_data in dropped_mounts:
		BehaviorEvents.emit_signal("OnDropMount", playerNode, drop_data.key, drop_data.idx)
		
	UpdateButtonVisibility()
		
	for drop_data in dropped_cargo:
		BehaviorEvents.emit_signal("OnDropCargo", playerNode, drop_data.src, drop_data.modified_attributes, drop_data.count)
	
func OnRequestObjectUnload_Callback(obj):
	if obj.get_attrib("type") == "player" and obj.get_attrib("ghost_memory") == null:
		playerNode = null
	
func OnObjTurn_Callback(obj):
	var is_player : bool = obj.get_attrib("type") == "player"

	if obj.get_attrib("animation.waiting_moving") == true:
		return
	
	# other stuff can happen when moving one block but we have to finish playing the anim
	# before we go again
	if is_player and obj.get_attrib("animation.in_movement") == true and obj.get_attrib("animation.waiting_moving") != true:
		obj.set_attrib("animation.waiting_moving", true)
		BehaviorEvents.emit_signal("OnWaitForAnimation")
		return
		
	var disabled_ship_turn = obj.get_attrib("offline_systems.ship", 0.0)
	if is_player and disabled_ship_turn > 0.0:
		lock_input = true
		var wait_time = min(1.0, disabled_ship_turn)
		BehaviorEvents.emit_signal("OnUseAP", obj, wait_time)
		return
		
	var delayed_logs = obj.get_attrib("delayed_logs", [])
	if is_player and not delayed_logs.empty():
		var msg_data
		var to_remove = []
		for index in range(delayed_logs.size()):
			msg_data = delayed_logs[index]
			if msg_data.get("msg_turn", Globals.total_turn) <= Globals.total_turn:
				BehaviorEvents.emit_signal("OnLogLine", msg_data.get("msg"), msg_data.get("msg_params"))
				to_remove.push_back(index)
		for index in to_remove:
			delayed_logs.remove(index)
		obj.set_attrib("delayed_logs", delayed_logs)
		
	# sometimes we put the player on cruise control. when we give him back control "ai" component will be disabled
	if is_player and obj.get_attrib("ai") == null:
		if obj.get_attrib("wait_for_hack", false) == true:
			print("********INVESTIGATE, WAIT_FOR_HACK IS TRUE WHILE WE ARE STARTING A NEW TURN!!!!!*********")
			
		lock_input = false
		Globals.LevelLoaderRef.SaveState(Globals.LevelLoaderRef.GetCurrentLevelData())
		
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
				#BehaviorEvents.emit_signal("OnLogLine", "Ship in range of %s", [Globals.mytr(filtered[0].get_attrib("name_id"))])
				BehaviorEvents.emit_signal("OnLogLine", "Ship in range of %s", [Globals.EffectRef.get_object_display_name(filtered[0])])
			elif filtered.size() > 1:
				BehaviorEvents.emit_signal("OnLogLine", "Multiple Objects Detected")
				
			# Same as AI
			ConsiderInterests(obj)
			
			UpdateMovementBasedButton()
	else:
		lock_input = true
		
		
func ConsiderInterests(obj):
	# Similar method called in AIBehavior if player is on Autopilot. If not, we process new object entering scanner here.
	# Assume this is called after we already validated obj is player and not on autopilot
	var level_id : String = Globals.LevelLoaderRef.GetLevelID()
	var new_objs : Array = obj.get_attrib("scanner_result.new_in_range." + level_id, [])
		
	# Disable if enemy came in range or never seen item shows up
	var filtered : Array = []
	var known_anomalies = obj.get_attrib("scanner_result.known_anomalies", {})
	for id in new_objs:
		var o : Node2D = Globals.LevelLoaderRef.GetObjectById(id)
		if o == null:
			continue
		if Globals.is_(o.get_attrib("ai.aggressive"), true):
			var log_choices = {
				"[color=yellow]Enemy ship entered scanner range![/color]":50,
				"[color=yellow]Enemy power signature detected![/color]":50,
				"[color=yellow]We're pickup an enemy signal on the wideband frequency![/color]":30,
				"[color=yellow]Enemy ship approaching![/color]":50,
				"[color=yellow]Shield up! Enemy in range![/color]":20,
				"[color=yellow]We've got incoming![/color]":10,
				"[color=yellow]Enemy in sight, shield at maximum![/color]":50,
				"[color=yellow]Defense protocol activated![/color]":10,
				"[color=yellow]Engaging combat pattern delta three![/color]":2,
				"[color=yellow]Enemy spotted! Evasive maneuver![/color]":20
			}
			BehaviorEvents.emit_signal("OnLogLine", log_choices)
			break
		var detected : bool = o.get_attrib("type") != "anomaly"
		if id in known_anomalies:
			detected = known_anomalies[id]
		if o.get_attrib("memory.was_seen_by", false) == false and detected == true:
			o.set_attrib("memory.was_seen_by", true)
			var log_choices = {
				"[color=yellow]Scanners have picked up a new %s[/color]":50,
				"[color=yellow]%s detected[/color]":30,
				"[color=yellow]%s within scanner range[/color]":30,
				"[color=yellow]Captain, I've just found a %s[/color]":5,
			}
			BehaviorEvents.emit_signal("OnLogLine", log_choices, [Globals.mytr(o.get_attrib("type"))])
			break

	
func Pressed_Weapon_Callback():
	if lock_input:
		return
	
	var weapons = playerNode.get_attrib("mounts.weapon")
	var weapons_data = Globals.LevelLoaderRef.LoadJSONArray(weapons)
	if weapons_data == null or weapons_data.size() <= 0:
		BehaviorEvents.emit_signal("OnLogLine", "Mount some weapon first")
		return
		
	var weapon_attributes = playerNode.get_attrib("mount_attributes.weapon")
		
	_weapon_shots = []
	for index in range(weapons_data.size()):
		var data = weapons_data[index]
		var attrib_data = weapon_attributes[index]
		if not Globals.EffectRef.IsInCooldown(playerNode, attrib_data):
			_weapon_shots.push_back({"state":SHOOTING_STATE.init, "weapon_data":data, "modified_attributes":attrib_data})
		else:
			BehaviorEvents.emit_signal("OnLogLine", "%s is in cooldown and need time to recharge", Globals.EffectRef.get_display_name(data, attrib_data))
		
	if _weapon_shots.size() <= 0:
		BehaviorEvents.emit_signal("OnLogLine", "None of our weapons are ready Captain!")
		return
		
	var cur_weapon = _weapon_shots[0]
	cur_weapon.state = SHOOTING_STATE.wait_targetting
	#BehaviorEvents.emit_signal("OnLogLine", "Firing " + cur_weapon.weapon_data.name_id + ". Target ?")
	BehaviorEvents.emit_signal("OnRequestTargettingOverlay", playerNode, cur_weapon, self, "ProcessAttackSelection")
	BehaviorEvents.emit_signal("OnPopGUI") #HUD
	#var text = Globals.mytr("[color=red]Select target for %s...[/color]", [Globals.mytr(cur_weapon.weapon_data.name_id)])
	var text = Globals.mytr("[color=red]Select target for %s...[/color]", [Globals.EffectRef.get_display_name(cur_weapon.weapon_data, cur_weapon.modified_attributes)])
	BehaviorEvents.emit_signal("OnPushGUI", "TargettingHUD", {"info_text":text, "show_skip":_weapon_shots.size() > 1})
	set_input_state(Globals.INPUT_STATE.weapon_targetting)
	
func OnLevelLoaded_Callback():
	lock_input = false
	
	if playerNode == null:
		
		var save = Globals.LevelLoaderRef.cur_save
		if save == null or not save.has("player_data"):
			_current_origin = PLAYER_ORIGIN.wormhole
		
		var template = "data/json/ships/player_default.json"
		if Globals.LevelLoaderRef._TEST_MID_GAME == true:
			template = "data/json/ships/mid_game_test.json"
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
			
		var modififed_attrib = null
		var rot := 0.0
		if save != null && save.has("player_data"):
			modififed_attrib = save.player_data.modified_attributes
			template = save.player_data.src
			if "rotation" in save.player_data:
				rot = save.player_data.rotation
		# Modified_attrib must be passed during request so that proper IDs can be locked in objByID
		playerNode = levelLoaderRef.RequestObject(template, coord, modififed_attrib)
		playerNode.z_index = 999
		playerNode.rotation = rot
		if playerNode.get_attrib("player_name") == null:
			playerNode.set_attrib("player_name", PermSave.get_attrib("settings.default_name", "Ombarus"))
		if playerNode.get_attrib("lowest_diff") == null:
			playerNode.set_attrib("lowest_diff", PermSave.get_attrib("settings.difficulty"))
		
		BehaviorEvents.emit_signal("OnPlayerCreated", playerNode)
		
		UpdateButtonVisibility()
		UpdateMovementBasedButton()
		
		# always default to saved position
		_current_origin = PLAYER_ORIGIN.saved
	
	var level_data = Globals.LevelLoaderRef.GetCurrentLevelData()
	if "level_message" in level_data:
		var message_to_play = level_data["level_message"]
		var played_messages = playerNode.get_attrib("played_messages", [])
		if not message_to_play in played_messages:
			BehaviorEvents.emit_signal("OnLogLine", message_to_play)
			played_messages.push_back(message_to_play)
			playerNode.set_attrib("played_messages", played_messages)
	
func _input(event):
	if OS.is_debug_build() and event.is_action_released("hide_hud"):
		get_node("../../Camera-GUI/SafeArea").visible = not get_node("../../Camera-GUI/SafeArea").visible
		get_node("../../Camera-GUI/ViewportContainer").visible = not get_node("../../Camera-GUI/ViewportContainer").visible
	if event.is_action_released("screenshot"):
		var cur_datetime : Dictionary = OS.get_datetime()
		var save_file_path = "user://screenshot-%s%s%s-%s%s%s.png" % [cur_datetime["year"], cur_datetime["month"], cur_datetime["day"], cur_datetime["hour"], cur_datetime["minute"], cur_datetime["second"]]
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png(save_file_path)
	
	if playerNode != null and event.is_action_released("touch") && _input_state != Globals.INPUT_STATE.camera_dragged :
		var click_pos = playerNode.get_global_mouse_position()
		if _input_state == Globals.INPUT_STATE.test:
			DO_TEST(click_pos)
	
	# if player is moving using pathfinding AI and we click anywhere we stop the ship. it must be on button "released"
	# because otherwise _unhandled_input will trigger and send the ship somewhere else
	if (event is InputEventMouseButton or event is InputEventKey) and playerNode != null and playerNode.get_attrib("ai") != null and playerNode.get_attrib("ai.disable_on_interest", false) == true and playerNode.get_attrib("ai.skip_check") <= 0:
		if event.is_pressed() == false:
			playerNode.set_attrib("ai.disabled", true)
			_double_tap_timer = 0.2
			_double_tap_action = "" # do nothing if not double-tap
		get_tree().set_input_as_handled() # don't do anything else this turn
	
	if _input_state != Globals.INPUT_STATE.look_around or not event is InputEventMouseButton:
		return
		
	if click_start_pos == null:
		click_start_pos = Vector2(0,0)
	if event.is_action_pressed("touch"):
		click_start_pos = event.position
	var vp_size : Vector2 = get_viewport().size
	var drag_vec : Vector2 = click_start_pos - event.position
	var per_drag_x : float = abs(drag_vec.x / vp_size.x)
	var per_drag_y : float = abs(drag_vec.y / vp_size.y)
	
	get_tree().set_input_as_handled()
	
	if not event.is_action_released("touch") or per_drag_x > 0.04 or per_drag_y > 0.04:
		return
	
	click_start_pos = Vector2(0,0)
	#print("player::_input set input to HUD")
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "HUD", null)
	set_input_state(Globals.INPUT_STATE.hud)
	
	var click_pos = playerNode.get_global_mouse_position()
	
	var tile = Globals.LevelLoaderRef.World_to_Tile(click_pos)
	var tile_content = Globals.LevelLoaderRef.levelTiles[tile.x][tile.y]
	var str_fmt = "There is %s here"
	var filtered_content = []
	for obj in tile_content:
		if obj.visible == true:
			var stackable = obj.get_attrib("equipment.stackable", false)
			var skip = false
			if stackable == true:
				for item in filtered_content:
					if item.get_attrib("src") == obj.get_attrib("src"):
						skip = true
						break
			if skip == false:
				filtered_content.push_back(obj)
		
	var scanner_level := 0
	var scanner_data = Globals.LevelLoaderRef.LoadJSONArray(playerNode.get_attrib("mounts.scanner"))
	if scanner_data != null and scanner_data.size() > 0:
		scanner_level = Globals.get_data(scanner_data[0], "scanning.level")
		
	if filtered_content.size() == 1:
		var owner = null
		# when object is a ship and has equipment with effects active, show the modified stats
		var applied_effects = filtered_content[0].get_attrib("applied_effects", [])
		if applied_effects.size() > 0:
			owner = filtered_content[0]
		BehaviorEvents.emit_signal("OnPushGUI", "Description", {"obj":filtered_content[0], "owner":owner, "modified_attributes":filtered_content[0].modified_attributes, "scanner_level":scanner_level})
	elif filtered_content.size() > 1:
		BehaviorEvents.emit_signal("OnPushGUI", "SelectTarget", {"targets":filtered_content, "callback_object":self, "callback_method":"LookTarget_Callback"})
	else:
		var log_choices = {
			"Nothing but empty space":150,
			"When you look in the void, the void looks back":1,
			"When you look in the void, the void didn't look back":10,
			"There's billions of stars in this tiny space but nothing else":50,
			"Analysis completed, nothing found":150,
			"Gravity well nominal":20
		}
		BehaviorEvents.emit_signal("OnLogLine", "Nothing but empty space")

	
func LookTarget_Callback(selected_targets):
	var scanner_level := 0
	var scanner_data = Globals.LevelLoaderRef.LoadJSONArray(playerNode.get_attrib("mounts.scanner"))
	if scanner_data != null and scanner_data.size() > 0:
		scanner_level = Globals.get_data(scanner_data[0], "scanning.level")
		
	if selected_targets.size() > 0:
		var owner = null
		# when object is a ship and has equipment with effects active, show the modified stats
		var applied_effects = selected_targets[0].get_attrib("applied_effects", [])
		if applied_effects.size() > 0:
			owner = selected_targets[0]
		BehaviorEvents.emit_signal("OnPushGUI", "Description", {"obj":selected_targets[0], "owner":owner, "modified_attributes":selected_targets[0].modified_attributes, "scanner_level":scanner_level})

func OnCameraDragged_Callback():
	if _input_state != Globals.INPUT_STATE.camera_dragged:
		_saved_input_state = _input_state
		#print("player::OnCameraDragged_Callback set input to CAMERA_DRAGGED")
		set_input_state(Globals.INPUT_STATE.camera_dragged)


func _unhandled_input(event):
	if lock_input or _input_state == Globals.INPUT_STATE.look_around or playerNode == null:
		return
		
	var dir = null
	
	if event is InputEventMouseButton:
		if event.is_action_pressed("touch"):
			click_start_time = OS.get_ticks_msec()
		elif event.is_action_released("touch") && _input_state != Globals.INPUT_STATE.camera_dragged :
			#print("player::_unhandled_input handle release")
			var click_pos = playerNode.get_global_mouse_position()
			
			if _input_state == Globals.INPUT_STATE.weapon_targetting:
				set_input_state(Globals.INPUT_STATE.hud)
				BehaviorEvents.emit_signal("OnTargetClick", click_pos, Globals.VALID_TARGET.attack)
			elif _input_state == Globals.INPUT_STATE.board_targetting:
				set_input_state(Globals.INPUT_STATE.hud)
				BehaviorEvents.emit_signal("OnTargetClick", click_pos, Globals.VALID_TARGET.board)
			elif _input_state == Globals.INPUT_STATE.loot_targetting:
				set_input_state(Globals.INPUT_STATE.hud)
				BehaviorEvents.emit_signal("OnTargetClick", click_pos, Globals.VALID_TARGET.loot)
			else:
				var player_pos = playerNode.position
				var clicked_tile = Globals.LevelLoaderRef.World_to_Tile(click_pos)
				click_pos = Globals.LevelLoaderRef.Tile_to_World(clicked_tile) # in case we clicked outside the world's bounds
				var player_tile = Globals.LevelLoaderRef.World_to_Tile(player_pos)
				
				var click_dir = click_pos - player_pos
				var rot = rad2deg(Vector2(0.0, 0.0).angle_to_point(click_dir)) - 90.0
				if rot < 0:
					rot += 360
					
				# Hold to avoid contextual default action
				if click_start_time == null or click_start_time + (1.2 * 1000) > OS.get_ticks_msec():
					var did_other_action : bool = do_contextual_actions(clicked_tile, player_tile)
					if did_other_action == true:
						return
				click_start_time = null
					
				# dead zone (click on sprite)
				if abs(click_dir.x) < levelLoaderRef.tileSize / 2 && abs(click_dir.y) < levelLoaderRef.tileSize / 2:
					wait_one_turn(playerNode)
					return
				
				##################
				if _double_tap_timer > 0.0:
					_double_tap_timer = 0.0
					_double_tap_action = ""
					BehaviorEvents.emit_signal("OnDoubleTap")
				else:
					_double_tap_timer = 0.2
					_double_tap_action = "apply_goto"
					_double_tap_tile = clicked_tile
				
#				# goto click pos
#				var ai_data = {
#					"aggressive":false,
#					"pathfinding":"simple",
#					"disable_on_interest":true,
#					"disable_wandering":true,
#					"skip_check":1 # make sure we move at least one tile, this means when danger is close we move one tile at a time
#					#"objective":clicked_tile
#				}
#				playerNode.set_attrib("ai", ai_data)
#				# Need to be done like this so Vector2 will be serialized properly
#				playerNode.set_attrib("ai.objective", clicked_tile)
#				BehaviorEvents.emit_signal("OnAttributeAdded", playerNode, "ai")
		elif event.is_action_released("touch") && _input_state == Globals.INPUT_STATE.camera_dragged:
			#print("player::_unhandled_input reset drag")
			set_input_state(_saved_input_state)
				
	if event is InputEventKey and event.pressed == true:
		if _input_state == Globals.INPUT_STATE.weapon_targetting or _input_state == Globals.INPUT_STATE.board_targetting or _input_state == Globals.INPUT_STATE.loot_targetting:
			return
			
		if event.unicode != 0:
			_last_unicode = PoolByteArray([event.unicode]).get_string_from_utf8()
		else:
			_last_unicode = ""
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
		if event.scancode == KEY_Q and OS.is_debug_build():
			if _input_state == Globals.INPUT_STATE.test:
				set_input_state(Globals.INPUT_STATE.hud)
			else:
				set_input_state(Globals.INPUT_STATE.test)
				
	if event is InputEventKey && event.pressed == false:
		if _input_state == Globals.INPUT_STATE.weapon_targetting or _input_state == Globals.INPUT_STATE.board_targetting or _input_state == Globals.INPUT_STATE.loot_targetting:
			#if _last_unicode == 's':
			#	get_node(TargettingHUD).emit_signal("skip_pressed")
			#if _last_unicode == 'c':
			#	get_node(TargettingHUD).emit_signal("cancel_pressed")
			return
			#get_node(TargettingHUD).emit_signal("cancel_pressed")
		
		if event.scancode == KEY_KP_5:
			wait_one_turn(playerNode)
		if _last_unicode == '?':
			BehaviorEvents.emit_signal("OnHUDQuestionPressed")
	if dir != null:
		#next_touch_is_a_goto = true
		BehaviorEvents.emit_signal("OnMovement", playerNode, dir)

func _process(delta):
	if _double_tap_timer > 0.0:
		_double_tap_timer -= delta
		if _double_tap_timer <= 0.0 and not _double_tap_action.empty():
			self.call(_double_tap_action)
			_double_tap_action = ""

func apply_goto():
	_double_tap_timer = 0.0
	_double_tap_action = ""
	# goto click pos
	var ai_data = {
		"aggressive":false,
		"pathfinding":"simple",
		"disable_on_interest":true,
		"disable_wandering":true,
		"skip_check":1 # make sure we move at least one tile, this means when danger is close we move one tile at a time
		#"objective":clicked_tile
	}
	playerNode.set_attrib("ai", ai_data)
	# Need to be done like this so Vector2 will be serialized properly
	playerNode.set_attrib("ai.objective", _double_tap_tile)
	BehaviorEvents.emit_signal("OnAttributeAdded", playerNode, "ai")


func do_contextual_actions(tile, player_tile):
	var content : Array = Globals.LevelLoaderRef.GetTile(tile)
	var dist = (tile - player_tile).length()
	var method_to_call : String = ""
	# This will tell the following loop if it can overwrite a method or not
	var priority : int = 0
	for o in content:
		if o == playerNode or o.visible == false or o.get_attrib("ghost_memory") != null:
			continue
			
		if o.get_attrib("equipment") != null:
			if tile == player_tile and priority < 100:
				method_to_call = "Pressed_Grab_Callback"
				priority = 100
				continue
			elif priority < 70:
				method_to_call = ""
				priority = 70
			
		if o.get_attrib("type") == "trade_port" and tile == player_tile and priority < 85:
			method_to_call = "Pressed_Comm_Callback"
			priority = 85
			continue
			
		if o.get_attrib("merchant") != null:
			var player_content : Array = Globals.LevelLoaderRef.GetTile(player_tile)
			var done := false
			for c in player_content:
				if c.get_attrib("type") == "trade_port" and priority < 85:
					method_to_call = "Pressed_Comm_Callback"
					priority = 85
					done = true
					break
			if done == true:
				continue
					
			
		if o.get_attrib("type") == "wormhole" and tile == player_tile and priority < 80:
			method_to_call = "Pressed_FTL_Callback"
			priority = 80
			continue
			
		if Globals.is_(o.get_attrib("cargo.transferable"), true) and dist < 2.0 and priority < 90:
			method_to_call = "Pressed_Take_Callback"
			priority = 90
			continue
			
		if o.get_attrib("destroyable") != null || o.get_attrib("harvestable") != null:
			var targetting_behavior : Node = get_node("../Targetting")
			
			var weapons = playerNode.get_attrib("mounts.weapon")
			var weapons_attributes = playerNode.get_attrib("mount_attributes.weapon")
			var weapons_data = Globals.LevelLoaderRef.LoadJSONArray(weapons)
			if weapons_data != null and weapons_data.size() > 0:
				for i in range(weapons_data.size()):
					var w = weapons_data[i]
					var attrib = weapons_attributes[i]
					var firing_data = targetting_behavior.ClosestFiringSolution(playerNode, player_tile, tile, {"weapon_data":w, "modified_attributes":attrib})
					var min_length = firing_data[2] # take AoE into account
					if min_length == 0:
						if o.get_attrib("destroyable") != null and priority < 200:
							priority = 200 # enemy ships have very high priority
							method_to_call = "Pressed_Weapon_Callback"
						elif priority < 10:
							priority = 10 # shooting planet is lowest priority
							method_to_call = "Pressed_Weapon_Callback"
						break
		#TODO: If more  than one possible contextual action maybe pop a menu ?
		#elif o.get_attrib("boardable") == true:
		#	return true
		
	if method_to_call != "":
		# Reset must be called before the contextual action
		# to reset the current highlight and not the one that will be triggered by the method call
		# (like picking up something with contextual action triggering the open inventory tuto)
		BehaviorEvents.emit_signal("OnResetHighlight")
		self.call(method_to_call)
		return true
			
	return false

func cancel_targetting_pressed_Callback():
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "HUD", null)
	set_input_state(Globals.INPUT_STATE.hud)
	

func OnResumeAttack_Callback():
	# At this point, all targets should already be selected, we resume applying damage and don't need parameters
	ProcessAttackSelection(null, null)

#TODO: if target is out-of-range the sequence will be aborted. Should probably fix that if you have more than one weapon
#TODO: when firing multiple weapon. If the slowest weapon would allow the fastest to attack twice it should query twice.
func ProcessAttackSelection(target, shot_tile):
	set_input_state(Globals.INPUT_STATE.hud)
	var cur_weapon = null
	for shot in _weapon_shots:
		if shot.state == SHOOTING_STATE.wait_damage:
			continue
		elif shot.state == SHOOTING_STATE.wait_targetting:
			shot["target"] = target
			shot["tile"] = shot_tile
			shot.state = SHOOTING_STATE.wait_damage
		elif shot.state == SHOOTING_STATE.init and cur_weapon == null:
			cur_weapon = shot
	
	if cur_weapon != null:
		cur_weapon.state = SHOOTING_STATE.wait_targetting
		#BehaviorEvents.emit_signal("OnLogLine", "Acknowledged, should we also fire " + cur_weapon.weapon_data.name_id + ". Target ?")
		BehaviorEvents.emit_signal("OnRequestTargettingOverlay", playerNode, cur_weapon, self, "ProcessAttackSelection")
		var text = Globals.mytr("[color=red]Select target for %s...[/color]", [Globals.EffectRef.get_display_name(cur_weapon.weapon_data, cur_weapon.modified_attributes)])
		get_node(TargettingHUD).Init( {"info_text":text} )
		set_input_state(Globals.INPUT_STATE.weapon_targetting)
		return
	
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "HUD", null)
	
	var all_canceled = true
	for shot in _weapon_shots:
		var shoot_empty = Globals.get_data(shot.weapon_data, "weapon_data.shoot_empty", false)
		# shot_tile is null if we skipped the shot
		if "target" in shot and shot.target != null or ("tile" in shot and shot.tile != null and shoot_empty):
			all_canceled = false
			break
			
	if all_canceled == true:
		return
	
	var started = false
	for shot in _weapon_shots:
		if shot.state == SHOOTING_STATE.done:
			started = true
			continue
		# if any weapon shot is "done" but we're still looping it means we were waiting for
		# electronic warfare select screen and we are already in a parallel action phase
		if started == false:
			BehaviorEvents.emit_signal("OnBeginParallelAction", playerNode)
			started = true
		var shoot_empty = Globals.get_data(shot.weapon_data, "weapon_data.shoot_empty", false)
		if shot.target != null:
			var valid_target := []
			if typeof(shot.target) == TYPE_ARRAY:
				for t in shot.target:
					var destroyed_state = t.get_attrib("destroyable.destroyed")
					if destroyed_state == null or destroyed_state == false:
						valid_target.push_back(t)
			else:
				valid_target.push_back(shot.target)	
			BehaviorEvents.emit_signal("OnDealDamage", valid_target, playerNode, shot.weapon_data, shot.modified_attributes, shot.tile)
		elif shot.target == null and shoot_empty and "tile" in shot and shot.tile != null:
			BehaviorEvents.emit_signal("OnDealDamage", [], playerNode, shot.weapon_data, shot.modified_attributes, shot.tile)
		shot.state = SHOOTING_STATE.done
		if playerNode.get_attrib("wait_for_hack", false) == true:
			break
	if playerNode.get_attrib("wait_for_hack", false) == false:
		BehaviorEvents.emit_signal("OnEndParallelAction", playerNode)
	
func ProcessBoardSelection(target, tile):
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "HUD", null)
	set_input_state(Globals.INPUT_STATE.hud)
	if target != null:
		var pnode = playerNode
		BehaviorEvents.emit_signal("OnTransferPlayer", pnode, target)
	else:
		BehaviorEvents.emit_signal("OnLogLine", "Ship transfer canceled")
	
func ProcessTakeSelection(target, tile):
	BehaviorEvents.emit_signal("OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "HUD", null)
	set_input_state(Globals.INPUT_STATE.hud)
	if target == null:
		BehaviorEvents.emit_signal("OnLogLine", "Item transfer canceled")
		return
		
	BehaviorEvents.emit_signal("OnPushGUI", "TransferInventoryV2", {"object1":playerNode, "object2":target})
	
func OnTradingCompleted_Callback():
	pass
	
func OnTransferPlayer_Callback(old_player, new_player):
	playerNode = new_player
	var log_choices = {
		"All controls transfered, the ship is ours captain !":50,
		"Boarding completed":50,
		"System online, transfer completed":50,
		"Affirmative Dave, I read you":1,
		"Boot sequence completed successfully":20
	}
	BehaviorEvents.emit_signal("OnLogLine", "All controls transfered, the ship is ours captain !")
	BehaviorEvents.emit_signal("OnUseAP", new_player, 1.0)

	UpdateButtonVisibility()
	old_player.z_index = 900
	new_player.z_index = 999
		
		
	new_player.set_attrib("moving.moved", true) # to update the wormhole button in next "OnPlayerTurn"
	new_player.set_attrib("player_name", old_player.get_attrib("player_name"))
	new_player.set_attrib("lowest_diff", old_player.get_attrib("lowest_diff"))
	
func DO_TEST(click_pos):
	playerNode.set_attrib("destroyable.current_hull", 1)
	BehaviorEvents.emit_signal("OnDamageTaken", playerNode, null, Globals.DAMAGE_TYPE.radiation)
			
	#BehaviorEvents.emit_signal("OnHideGUI", "Options")
	#BehaviorEvents.emit_signal("OnShowGUI", "Options", null, "slow_popin")


func Pressed_Question_Callback():
	BehaviorEvents.emit_signal("OnPushGUI", "Tutorial", {})

func Pressed_Option_Callback():
	BehaviorEvents.emit_signal("OnPushGUI", "Options", {})
	
func UpdateMovementBasedButton():
	var tile_pos = Globals.LevelLoaderRef.World_to_Tile(playerNode.position)
	var content = Globals.LevelLoaderRef.levelTiles[tile_pos.x][tile_pos.y]
	var filtered = []
	var wormhole = null
	var trade_port = null
	for c in content:
		if c != playerNode and c.get_attrib("type") in ["wormhole"]:
			wormhole = c
		if c != playerNode and c.get_attrib("type") in ["trade_port"]:
			trade_port = c
			
	var btn = ftl_btn_ref_1
	if wormhole != null:
		btn.visible = true
		var cur_depth : int = Globals.LevelLoaderRef.current_depth
		var worm_depth : int = wormhole.get_attrib("depth")
		if worm_depth <= cur_depth:
			btn.Text = "[<]FTL"
		else:
			btn.Text = "[>]FTL"
	else:
		btn.visible = false
		
	btn = comm_btn_ref
	btn.EnableComm(trade_port != null)
	if trade_port != null:
		BehaviorEvents.emit_signal("OnLogLine", "Select 'Comm' to open a trading console")
