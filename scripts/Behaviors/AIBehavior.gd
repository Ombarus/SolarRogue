extends Node

export(NodePath) var targetting
var _targetting

func _ready():
	_targetting = get_node(targetting)
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnDamageTaken", self, "OnDamageTaken_Callback")
	BehaviorEvents.connect("OnScannerUpdated", self, "OnScannerUpdated_Callback")
	BehaviorEvents.connect("OnAttributeAdded", self, "OnAttributeAdded_Callback")
	BehaviorEvents.connect("OnTriggerAnomaly", self, "OnTriggerAnomaly_Callback")
	BehaviorEvents.connect("OnSystemDisabled", self, "OnSystemDisabled_Callback")
	
func OnSystemDisabled_Callback(obj, system):
	if not "scanner" in system or obj.get_attrib("ai") == null:
		return
		
	if obj.get_attrib("ai.target") != null:
		obj.set_attrib("ai.pathfinding", "simple")
		obj.set_attrib("ai.target", null)
		obj.set_attrib("wandering", true)
		BehaviorEvents.emit_signal("OnStatusChanged", obj)
	
func OnAttributeAdded_Callback(obj, added_name):
	if added_name == "ai":
		ConsiderInterests(obj)
		if obj.get_attrib("ai") != null:
			OnObjTurn_Callback(obj)
	
func OnTriggerAnomaly_Callback(obj, anomaly):
	if obj.get_attrib("ai.disable_on_interest", false) == true:
		obj.set_attrib("ai.disabled", true)
	
func ConsiderInterests(obj):
	if obj.get_attrib("ai.skip_check") > 0:
		return
	var level_id : String = Globals.LevelLoaderRef.GetLevelID()
	var new_objs : Array = obj.get_attrib("scanner_result.new_in_range." + level_id, [])
	var is_player : bool = obj.get_attrib("type") == "player"
	
	# When going down a wormhole, the objects around the wormhole will be "new"
	# for this turn, but we are not moving yet so it's ok
	var moved = obj.get_attrib("moving.moved")
	
	# Disable if enemy came in range or never seen item shows up
	var filtered : Array = []
	var known_anomalies = obj.get_attrib("scanner_result.known_anomalies", {})
	if moved != null and moved == true:
		for id in new_objs:
			var o : Node2D = Globals.LevelLoaderRef.GetObjectById(id)
			if o == null:
				continue
			if Globals.is_(o.get_attrib("ai.aggressive"), true):
				if is_player == true:
					var log_choices = {
						"[color=yellow]Enemy ship entered scanner range![/color]":50,
						"[color=yellow]Enemy power signature detected![/color]":50,
						"[color=yellow]We're pickup an enemy signal on the wideband frequency![/color]":30,
						"[color=yellow]Enemy ship approaching![/color]":50,
						"[color=yellow]Shield up! Enemy in range![/color]":20,
						"[color=yellow]We've got incoming![/color]":10
					}
					BehaviorEvents.emit_signal("OnLogLine", log_choices)
				filtered.push_back(id)
				break
			var detected : bool = o.get_attrib("type") != "anomaly"
			if id in known_anomalies:
				detected = known_anomalies[id]
			if o.get_attrib("memory.was_seen_by", false) == false and detected == true:
				if is_player == true:
					o.set_attrib("memory.was_seen_by", true)
					var log_choices = {
						"[color=yellow]Scanners have picked up a new %s[/color]":50,
						"[color=yellow]%s detected[/color]":30,
						"[color=yellow]%s within scanner range[/color]":30,
						"[color=yellow]Captain, I've just found a %s[/color]":5,
					}
					BehaviorEvents.emit_signal("OnLogLine", log_choices, [Globals.mytr(o.get_attrib("type"))])
				filtered.push_back(id)
				break
			
	if filtered.size() > 0:
		for id in filtered:
			var o : Node2D = Globals.LevelLoaderRef.GetObjectById(filtered[0])
			if o != null:
				BehaviorEvents.emit_signal("OnScannerPickup", o.get_attrib("type", ""))
				break
		
	# Disable if enemy ship in range
	var cur_objs : Array = obj.get_attrib("scanner_result.cur_in_range." + level_id, [])
	var filtered_cur : Array = []
	for id in cur_objs:
		var o : Node2D = Globals.LevelLoaderRef.GetObjectById(id)
		if o != null and Globals.is_(o.get_attrib("ai.aggressive"), true):
			var e_tile = Globals.LevelLoaderRef.World_to_Tile(o.position)
			var p_tile = Globals.LevelLoaderRef.World_to_Tile(obj.position)
			if (e_tile - p_tile).length() < 7.0:
				# Print stop message ?
				if is_player == true:
					var log_choices = {
						"[color=yellow]Autopilot canceled, enemy too close ![/color]":50,
						"[color=yellow]Enemy nearby, let's take it slow![/color]":50,
						"[color=yellow]Enemy contact! Autopilot disabled![/color]":10
					}
					BehaviorEvents.emit_signal("OnLogLine", log_choices)
				filtered.push_back(id)
		if o != null:
			var detected : bool = o.get_attrib("type") != "anomaly"
			if id in known_anomalies:
				detected = known_anomalies[id]
			if o.get_attrib("memory.was_seen_by", false) == false and detected == true:
				if is_player == true:
					o.set_attrib("memory.was_seen_by", true)
			
	var should_ask = obj.get_attrib("ai.ask_on_interest", false)
	if filtered.size() > 0:
		if should_ask:
			BehaviorEvents.emit_signal("OnPushGUI", "ValidateDiag", {"callback_object":self, "callback_method":"On_Interest_Callback", "cancel_method":"On_Interest_Continue", "callback_param":obj, "custom_text":"Enemy in range! Stop current activity?"})
		obj.set_attrib("ai.disabled", true)
		
	# Disable if energy is low
	var cur_energy = obj.get_attrib("converter.stored_energy")
	if cur_energy != null and cur_energy <= 500:
		if is_player == true:
			BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]Energy too low for autopilot ![/color]")
		if should_ask:
			BehaviorEvents.emit_signal("OnPushGUI", "ValidateDiag", {"callback_object":self, "callback_method":"On_Interest_Callback", "cancel_method":"On_Interest_Continue", "callback_param":obj, "custom_text":"Energy Low! Stop current activity?"})
		obj.set_attrib("ai.disabled", true)
	
func On_Interest_Callback(obj):
	obj.set_attrib("ai.disabled", true)
	if obj.get_attrib("ai.pathfinding") == "crafting":
		BehaviorEvents.emit_signal("OnCancelCrafting", obj)
	
func On_Interest_Continue(obj):
	obj.set_attrib("ai.disabled", false)
	# will make AI take a turn
	BehaviorEvents.emit_signal("OnAttributeAdded", obj, "ai")
	
	
func OnScannerUpdated_Callback(obj):
			
	if obj.get_attrib("ai") == null or obj.get_attrib("ai.aggressive") == false:
		return
	
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var new_objs = obj.get_attrib("scanner_result.new_in_range." + level_id, [])
	#var new_out_objs = obj.get_attrib("scanner_result.new_out_of_range." + level_id)
	
	var player = null
	var in_range = false
	for id in new_objs:
		var o = Globals.LevelLoaderRef.GetObjectById(id)
		if o != null and o.get_attrib("type") == "player":
			in_range = true
			player = id
			break
	
	if in_range == true:
		if obj.get_attrib("ai.pathfinding") != "queen":
			obj.set_attrib("ai.pathfinding", "attack")
		obj.set_attrib("ai.target", player)
		obj.set_attrib("wandering", false)
		obj.set_attrib("ai.unseen_for", 0)
		BehaviorEvents.emit_signal("OnStatusChanged", obj)
	

	
func OnDamageTaken_Callback(target, shooter, damage_type):
	if target.get_attrib("ai") == null or shooter == null:
		return
	
	var run_if_attacked = target.get_attrib("ai.run_if_attacked")
	if run_if_attacked != null and run_if_attacked == true:
		target.set_attrib("ai.pathfinding", "run_away")
		target.set_attrib("ai.run_from", shooter.modified_attributes.unique_id)
		target.set_attrib("ai.unseen_for", 0)
		target.set_attrib("wandering", false)
		
	# handle the case where the player has better weapon and shoot a ship that hasn't seen it yet
	if target.get_attrib("ai.aggressive", false) == true:
		if target.get_attrib("ai.pathfinding") != "queen":
			target.set_attrib("ai.pathfinding", "attack")
		target.set_attrib("ai.target", shooter.get_attrib("unique_id"))
		target.set_attrib("wandering", false)
		target.set_attrib("ai.unseen_for", 0)
		BehaviorEvents.emit_signal("OnStatusChanged", target)
		
	if target.get_attrib("ai.aggressive_if_attacked", false) == true:
		target.set_attrib("ai.pathfinding", "attack")
		target.set_attrib("ai.aggressive", true)
		target.set_attrib("ai.unseen_for", 0)
		target.set_attrib("ai.target", shooter.get_attrib("unique_id"))
		target.set_attrib("wandering", false)
		BehaviorEvents.emit_signal("OnStatusChanged", target)
		
	# summon police
	if target.get_attrib("ai.agressive", false) == false:
		for ship in Globals.LevelLoaderRef.objByType["ship"]:
			if ship.get_attrib("ai.police_awareness", false) == true:
				ship.set_attrib("ai.aggressive", true)
				ship.set_attrib("ai.unseen_for", 0)
				ship.set_attrib("ai.pathfinding", "attack")
				ship.set_attrib("ai.target", shooter.get_attrib("unique_id"))
				ship.set_attrib("wandering", false)
				BehaviorEvents.emit_signal("OnStatusChanged", ship)
	
func OnObjTurn_Callback(obj):
	if obj.get_attrib("ai") == null:
		return
		
	# other stuff can happen when moving one block but we have to finish playing the anim
	# before we go again
	if obj.get_attrib("animation.in_movement") == true:
		BehaviorEvents.emit_signal("OnWaitForAnimation")
		obj.set_attrib("animation.waiting_moving", true)
		return
		
	var disabled_ship_turn = obj.get_attrib("offline_systems.ship", 0.0)
	if disabled_ship_turn > 0.0:
		var wait_time = min(1.0, disabled_ship_turn)
		BehaviorEvents.emit_signal("OnUseAP", obj, wait_time)
		return
		
	if obj.get_attrib("ai.disable_on_interest") == true:
		ConsiderInterests(obj)
		if obj.get_attrib("ai") == null:
			# hack to force AP Behavior to re-evaluate player after disabling AI in the same turn
			BehaviorEvents.emit_signal("OnUseAP", obj, 0.01)
			return
	
	obj.set_attrib("ap.ai_acted", false)
	#obj.modified_attributes["ap"] = false
	
	var pathfinding = obj.get_attrib("ai.pathfinding")
		
	var is_aggressive = obj.get_attrib("ai.aggressive")
	
	if pathfinding == "crafting":
		DoCraftingWait(obj)
	elif pathfinding == "pylon":
		DoPylonPathfinding(obj)
	elif pathfinding == "queen":
		DoJergQueenPathfinding(obj)
	elif pathfinding == "simple" or pathfinding == "group_leader":
		DoSimplePathFinding(obj)
	elif pathfinding == "group":
		DoFollowGroupLeader(obj)
	elif pathfinding == "run_away":
		DoRunAwayPathFinding(obj)
	elif pathfinding == "attack":
		DoAttackPathFinding(obj)
	else:
		# For now, just do nothing for one AP
		BehaviorEvents.emit_signal("OnUseAP", obj, 1.0)
		
	# ai might have been disabled for the player so don't force it to act
	if obj.get_attrib("ai") != null and obj.get_attrib("ap.ai_acted") == false:
		print("**** AI DID NOT DO ANY ACTION. AI SHOULD AT LEAST WAIT FOR 1 TURN ALWAYS ! *****")
		BehaviorEvents.emit_signal("OnUseAP", obj, 1.0)
		
	var skip_check = obj.get_attrib("ai.skip_check")
	if skip_check != null and skip_check > 0:
		obj.set_attrib("ai.skip_check", skip_check - 1)

func FindRandomTile():
	var x = MersenneTwister.rand(Globals.LevelLoaderRef.levelSize.x)
	var y = MersenneTwister.rand(Globals.LevelLoaderRef.levelSize.y)
	return Vector2(x,y)

func RotatedTileContent(obj, offset : Vector2) -> Array:
	var center_tile : Vector2 = Globals.LevelLoaderRef.World_to_Tile(obj.position)
	var desired_tile : Vector2 = center_tile + offset.rotated(obj.rotation)
	desired_tile = desired_tile.round()
	var tile_content = Globals.LevelLoaderRef.GetTile(desired_tile)
	return Globals.LevelLoaderRef.GetTile(desired_tile)

func DoCraftingWait(obj):
	var ap_left = obj.get_attrib("ai.objective")
	var consume = min(1.0, ap_left)
	if consume > 0.0:
		ap_left -= consume
		obj.set_attrib("ai.objective", ap_left)
		if ap_left <= 0.0:
			obj.set_attrib("ai.disabled", true) # disable here so that OnUseAP re-activate the player
			BehaviorEvents.emit_signal("OnResumeCrafting", obj)
		BehaviorEvents.emit_signal("OnUseAP", obj, consume)

func DoJergQueenPathfinding(obj):
	var ai_target = obj.get_attrib("ai.target")
	var runaway_cooldown = obj.get_attrib("ai.run_cooldown", 0)
	var queen_drones = []
	if "drone" in Globals.LevelLoaderRef.objByType:
		queen_drones = Globals.LevelLoaderRef.objByType["drone"]
		
	if runaway_cooldown > 0:
		runaway_cooldown -= 1
		obj.set_attrib("ai.run_cooldown", runaway_cooldown)
		
	if obj.get_attrib("offline_systems.converter", 0.0) <= 0.0 and ( \
		(queen_drones.size() < obj.get_attrib("spawner.max", 0) and ai_target == null) or \
		(ai_target != null and MersenneTwister.rand(10) < 2)):
			
		var queen_pos : Vector2 = Globals.LevelLoaderRef.World_to_Tile(obj.position)
		var positions = obj.get_attrib("spawner.favored_position", [])
		var spawned = false
		for offset in positions:
			if RotatedTileContent(obj, Vector2(offset[0], offset[1])).empty():
				spawned = true
				var offset_v := Vector2(offset[0], offset[1])
				var drone_node = Globals.LevelLoaderRef.RequestObject(obj.get_attrib("spawner.spawn"), (queen_pos + offset_v.rotated(obj.rotation)).round())
				drone_node.rotation = obj.rotation
				animate_spawn(drone_node)
				break
		if spawned == false:
			var fallback_pos = obj.get_attrib("spawner.fallback_position", [0, 0])
			var drone_node = Globals.LevelLoaderRef.RequestObject(obj.get_attrib("spawner.spawn"), queen_pos + Vector2(fallback_pos[0], fallback_pos[1]))
			drone_node.rotation = obj.rotation
		BehaviorEvents.emit_signal("OnUseAP", obj, obj.get_attrib("spawner.speed"))
		return
		
	elif ai_target == null:
		DoSimplePathFinding(obj)
		return
		
	if (runaway_cooldown > 0 or queen_drones.size() > 0) and ai_target != null:
		DoAttackPathFinding(obj)
		return
	elif ai_target != null:
		if obj.get_attrib("ai.run_from") == null:
			obj.set_attrib("ai.run_from", ai_target)
			obj.set_attrib("ai.unseen_for", 0)
		DoRunAwayPathFinding(obj)
		
func animate_spawn(n : Attributes):
	if n.get_attrib("animation.crafted", "").empty():
		return
		
	# This whole thing is to check if the spawned drone is visible to the player
	# if it's not visible, skip the spawn animation
	# I do this by checking the current result of the scanner's tilemap value for the spawned tile
	var fow = get_node("../../BG/FoW")
	if fow.visible == true:
		var player = Globals.get_first_player()
		var level_id = Globals.LevelLoaderRef.GetLevelID()
		var tile_memory = player.get_attrib("memory." + level_id + ".tiles")
		var tile = Globals.LevelLoaderRef.World_to_Tile(n.position)
		var memory_index = (((tile.y+1) * (Globals.LevelLoaderRef.levelSize.x+2)) + (tile.x+1))*4+0
		if memory_index < tile_memory.size() and tile_memory[memory_index] > 1.0:
			return
		
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	n.visible = false
	n.modulate.a = 0
	
	var fx = Preloader.CraftShipFX.instance()
	fx.position = n.position
	fx.rotation = n.rotation
	var r = get_node("/root/Root/GameTiles")
	call_deferred("safe_start", fx, r, n)

func DoPylonPathfinding(obj):
	var target = null
	if "mothership" in Globals.LevelLoaderRef.objByType:
		var motherships : Array = Globals.LevelLoaderRef.objByType["mothership"]
		if motherships.size() > 0:
			target = motherships[0]
			
	if target == null:
		BehaviorEvents.emit_signal("OnUseAP", obj, 10.0)
		return
		
	var cur_shield = target.get_attrib("shield.current_hp", 0)
	var max_shield = target.get_max_shield()
	var pylon_heal = obj.get_attrib("ai.pylon_heal")
	var cooldown_range = obj.get_attrib("ai.pylon_cooldown")
	var cooldown = MersenneTwister.rand(cooldown_range[1] - cooldown_range[0]) + cooldown_range[0]
	if cur_shield > max_shield - pylon_heal: # nothing to heal
		BehaviorEvents.emit_signal("OnUseAP", obj, cooldown)
		return
		
	target.set_attrib("shield.current_hp", min(max_shield, cur_shield + pylon_heal))
	
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	var n : Node2D = Preloader.PylonFX.instance()
	n.position = obj.position
	var r = get_node("/root/Root/GameTiles")
	call_deferred("safe_start", n, r, target.position)
	BehaviorEvents.emit_signal("OnUseAP", obj, cooldown)
	BehaviorEvents.emit_signal("OnDamageTaken", target, null, Globals.DAMAGE_TYPE.shield_hit)
	
func safe_start(n, r, target_pos):
	r.add_child(n)
	n.Start(target_pos)
	

func DoFollowGroupLeader(obj):
	if obj.get_attrib("ai.target") == null:
		
		var ships = []
		if "ship" in Globals.LevelLoaderRef.objByType:
			ships = Globals.LevelLoaderRef.objByType["ship"]
		var nearest = null
		var nearest_dist = 0
		for ship in ships:
			var pathfinding = ""
			if ship != null:
				pathfinding = ship.get_attrib("ai.pathfinding")
			if pathfinding == "group_leader" or pathfinding == "queen":
				var dist = (ship.position - obj.position).length()
				if nearest == null or nearest_dist > dist:
					nearest_dist = dist
					nearest = ship
		
		if nearest != null:
			var id = nearest.get_attrib("unique_id")
			var leader_tile = Globals.LevelLoaderRef.World_to_Tile(nearest.position)
			var my_tile = Globals.LevelLoaderRef.World_to_Tile(obj.position)
			var offset = my_tile - leader_tile
			offset = offset.rotated(-nearest.rotation).round()
			obj.set_attrib("ai.target", id)
			obj.set_attrib("ai.target_offset", offset)
				
	var target_id = obj.get_attrib("ai.target")
	# lost the leader, go back to regular pathfinding
	if target_id == null:
		obj.set_attrib("ai.pathfinding", "simple")
		return
		
	var target_obj = Globals.LevelLoaderRef.GetObjectById(target_id)
	# lost the leader, go back to regular pathfinding
	if target_obj == null:
		obj.set_attrib("ai.pathfinding", "simple")
		return
	
	# Police start non-aggressive, but if the leader become aggressive, the rest of the group will follow
	# I'm doing this like that because I have in mind that only the group leader knows the location of the
	# player and the other ships will only attack once they get in range of the player instead of
	# breaking formation and heading as quickly as possible to the player individually
	obj.set_attrib("ai.aggressive", target_obj.get_attrib("ai.aggressive", true))
	
	var target_offset = obj.get_attrib("ai.target_offset")
	target_offset = target_offset.rotated(target_obj.rotation)
	target_offset.x = round(target_offset.x)
	target_offset.y = round(target_offset.y)
	
	var desired_tile = Globals.LevelLoaderRef.World_to_Tile(target_obj.position)+target_offset
	var bounds = Globals.LevelLoaderRef.levelSize
	desired_tile[0] = clamp(desired_tile[0], 0, bounds.x-1)
	desired_tile[1] = clamp(desired_tile[1], 0, bounds.y-1)
	
	obj.set_attrib("ai.objective", desired_tile)
	DoSimplePathFinding(obj)
	
func update_unseen(obj : Attributes, target : Attributes) -> Vector2:
	var my_pos = obj.position
	var target_pos = target.position
	my_pos = Globals.LevelLoaderRef.World_to_Tile(my_pos)
	target_pos = Globals.LevelLoaderRef.World_to_Tile(target_pos)
	var scanner_range = 0
	var scanner = obj.get_attrib("mounts.scanner")
	var scanner_json = null
	if scanner != null:
		scanner_json = scanner[0]
	if scanner_json != null and scanner_json != "":
		var scanner_data = Globals.LevelLoaderRef.LoadJSON(scanner_json)
		scanner_range = scanner_data.scanning.radius
	var distance = my_pos - target_pos
	var distance_f = distance.length()
	if distance_f > scanner_range:
		obj.set_attrib("ai.unseen_for", obj.get_attrib("ai.unseen_for", 0) + 1)
	else:
		obj.set_attrib("ai.unseen_for", 0)
		
	return distance

func DoAttackPathFinding(obj):
	var player = Globals.LevelLoaderRef.GetObjectById(obj.get_attrib("ai.target"))
	
	if player == null:
		obj.set_attrib("ai.pathfinding", "simple")
		obj.set_attrib("ai.target", null)
		obj.set_attrib("wandering", true)
		BehaviorEvents.emit_signal("OnStatusChanged", obj)
		return
		
	if player.get_attrib("animation.in_movement") == true:
		BehaviorEvents.emit_signal("OnWaitForAnimation")
		player.set_attrib("animation.waiting_moving", true)
		obj.set_attrib("ap.ai_acted", true) # hack to make the AI exit without using it's turn
		return
		
	var distance = update_unseen(obj, player)
	var stop_running_after = obj.get_attrib("ai.stop_running_after", 0)
	
	if stop_running_after > 0 and obj.get_attrib("ai.unseen_for", 0) > stop_running_after:
		obj.set_attrib("ai.pathfinding", "simple")
		obj.set_attrib("ai.target", null)
		obj.set_attrib("wandering", true)
		BehaviorEvents.emit_signal("OnStatusChanged", obj)
		return
		
		
	var player_tile = Globals.LevelLoaderRef.World_to_Tile(player.position)
	var obj_tile = Globals.LevelLoaderRef.World_to_Tile(obj.position)
	var weapons = obj.get_attrib("mounts.weapon")
	var modified_attributes = obj.get_attrib("mount_attributes.weapon")
	var weapons_data = Globals.LevelLoaderRef.LoadJSONArray(weapons)
	
	var minimal_move = null
	var shot = false
	var weapon_enabled : bool = obj.get_attrib("offline_systems.weapon", 0.0) <= 0.0
	BehaviorEvents.emit_signal("OnBeginParallelAction", obj)
	for index in range(weapons_data.size()):
		var data = weapons_data[index]
		var attrib_data = modified_attributes[index]
		weapon_enabled = weapon_enabled and not Globals.EffectRef.IsInCooldown(obj, attrib_data)
		var move_info = _targetting.ClosestFiringSolution(obj, obj_tile, player_tile, {"weapon_data":data, "modified_attributes":attrib_data})
		var best_move = move_info[0]
		var best_tile = move_info[1]
		var min_length = move_info[2] # take AoE into account
		var is_destroyed = player.get_attrib("destroyable.destroyed")
		if weapon_enabled == true and min_length == 0 and (is_destroyed == null or is_destroyed == false):
			BehaviorEvents.emit_signal("OnDealDamage", [player], obj, data, attrib_data, best_tile)
			shot = true
		if minimal_move == null or minimal_move.length() > best_move.length():
			minimal_move = best_move
	BehaviorEvents.emit_signal("OnEndParallelAction", obj)

	if shot == false:
		var move_by = Vector2(0, 0)
		move_by.x = clamp(minimal_move.x, -1, 1)
		move_by.y = clamp(minimal_move.y, -1, 1)
		if move_by.length_squared() > 0.0:
			BehaviorEvents.emit_signal("OnMovement", obj, move_by)
		else:
			obj.set_attrib("ai.run_from", obj.get_attrib("ai.target"))
			DoRunAwayPathFinding(obj)

func DoSimplePathFinding(obj):
	if obj.get_attrib("wandering") == null and obj.get_attrib("ai.disable_wandering") == null or obj.get_attrib("ai.disable_wandering") == false:
		obj.modified_attributes["wandering"] = true
	
	var tile_pos = Globals.LevelLoaderRef.World_to_Tile(obj.position)
	var cur_pathfinding = obj.get_attrib("ai.pathfinding")

	var cur_objective = obj.get_attrib("ai.objective")
	if cur_pathfinding != "group" and (cur_objective == null || cur_objective == tile_pos):
		obj.set_attrib("ai.objective", FindRandomTile())
	
	var target = obj.get_attrib("ai.objective")
	var move_by = Vector2(0,0)
	if target.x > tile_pos.x:
		move_by.x += 1
	elif target.x < tile_pos.x:
		move_by.x -= 1
	if target.y > tile_pos.y:
		move_by.y += 1
	elif target.y < tile_pos.y:
		move_by.y -= 1
		
	if move_by.length_squared() > 0:
		BehaviorEvents.emit_signal("OnMovement", obj, move_by)
	else:
		# wait a turn if no where to go
		# Should be only when ai is in a group and waiting for the group's leader
		BehaviorEvents.emit_signal("OnUseAP", obj, 1.0)
		
	if tile_pos + move_by == cur_objective or obj.get_attrib("moving.moved") == false:
		if obj.get_attrib("ai.disable_on_interest") != null and obj.get_attrib("ai.disable_on_interest") == true:
			obj.set_attrib("ai.disabled", true)

func DoRunAwayPathFinding(obj):
	var my_pos = obj.position
	var from_id = Globals.LevelLoaderRef.objById[obj.modified_attributes.ai.run_from]
	var distance := Vector2(1.0, 0.0)
	if from_id != null:
		distance = update_unseen(obj, from_id)
		
	var distance_f := distance.length()
		
	var cancel_run := false
	var failed_max = obj.get_attrib("ai.failed_run_attempt", 0)
	if failed_max > 0:
		var cur_attempt = obj.get_attrib("ai.failed_run_cur_attempt", 0)
		var prev_dist = obj.get_attrib("ai.prev_run_distance", 0)
		if distance_f <= prev_dist:
			cur_attempt += 1
		if cur_attempt >= failed_max:
			obj.set_attrib("ai.run_cooldown", obj.get_attrib("ai.failed_cooldown"))
			cancel_run = true
		obj.set_attrib("ai.failed_run_cur_attempt", cur_attempt)
		obj.set_attrib("ai.prev_run_distance", distance_f)
	
	if cancel_run or obj.get_attrib("ai.unseen_for") > obj.get_attrib("ai.stop_running_after", 1):
		#TODO: Maybe wrap this in a method too ?
		obj.modified_attributes.ai.erase("pathfinding")
		obj.modified_attributes.ai.erase("run_from")
		obj.modified_attributes.ai.erase("unseen_for")
		if not cancel_run: # don't clear target if we couldn't run away
			obj.modified_attributes.ai.erase("target")
		obj.modified_attributes.ai.erase("failed_run_cur_attempt")
		obj.modified_attributes.ai.erase("prev_run_distance")
		obj.modified_attributes.erase("wandering")
		BehaviorEvents.emit_signal("OnUseAP", obj, 0.1) # trick to make the AI act again quickly
		return
		
		
	if distance_f <= 0.1:
		BehaviorEvents.emit_signal("OnMovement", obj, Vector2(1, 0))
		return
	
	if abs(distance.x) > abs(distance.y):
		distance = distance / abs(distance.x)
		distance.x += 0.1
	else:
		distance = distance / abs(distance.y)
		distance.y += 0.1
	
	var dir = Vector2(int(round(distance.x)), int(round(distance.y)))
	BehaviorEvents.emit_signal("OnMovement", obj, dir)
	
	
	

