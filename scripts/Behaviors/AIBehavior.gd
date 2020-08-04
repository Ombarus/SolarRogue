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
						"[color=yellow]would %s be useful right now captain?[/color]":5,
					}
					BehaviorEvents.emit_signal("OnLogLine", log_choices, [Globals.mytr(o.get_attrib("type"))])
				filtered.push_back(id)
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
			
	if filtered.size() > 0:
		obj.set_attrib("ai.disabled", true)
		
	# Disable if energy is low
	var cur_energy = obj.get_attrib("converter.stored_energy")
	if cur_energy != null and cur_energy <= 500:
		if is_player == true:
			BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]Energy too low for autopilot ![/color]")
		obj.set_attrib("ai.disabled", true)
	
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
		obj.set_attrib("ai.pathfinding", "attack")
		obj.set_attrib("ai.target", player)
		obj.set_attrib("wandering", false)
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
		target.set_attrib("ai.pathfinding", "attack")
		target.set_attrib("ai.target", shooter.get_attrib("unique_id"))
		target.set_attrib("wandering", false)
		BehaviorEvents.emit_signal("OnStatusChanged", target)
		
	if target.get_attrib("ai.aggressive_if_attacked", false) == true:
		target.set_attrib("ai.pathfinding", "attack")
		target.set_attrib("ai.aggressive", true)
		target.set_attrib("ai.target", shooter.get_attrib("unique_id"))
		target.set_attrib("wandering", false)
		BehaviorEvents.emit_signal("OnStatusChanged", target)
		
	# summon police
	if target.get_attrib("ai.agressive", false) == false:
		for ship in Globals.LevelLoaderRef.objByType["ship"]:
			if ship.get_attrib("ai.police_awareness", false) == true:
				ship.set_attrib("ai.aggressive", true)
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
	
	
	if pathfinding == "simple" or pathfinding == "group_leader":
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

func DoFollowGroupLeader(obj):
	if obj.get_attrib("ai.target") == null:
		
		var ships = []
		if "ship" in Globals.LevelLoaderRef.objByType:
			ships = Globals.LevelLoaderRef.objByType["ship"]
		var nearest = null
		var nearest_dist = 0
		for ship in ships:
			if ship != null and ship.get_attrib("ai.pathfinding") == "group_leader":
				var dist = (ship.position - obj.position).length()
				if nearest == null or nearest_dist > dist:
					nearest_dist = dist
					nearest = ship
		
		if nearest != null:
			var id = nearest.get_attrib("unique_id")
			var leader_tile = Globals.LevelLoaderRef.World_to_Tile(nearest.position)
			var my_tile = Globals.LevelLoaderRef.World_to_Tile(obj.position)
			var offset = my_tile - leader_tile
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
	

func DoAttackPathFinding(obj):
	var player = Globals.LevelLoaderRef.GetObjectById(obj.get_attrib("ai.target"))
	if player == null:
		obj.set_attrib("ai.pathfinding", "simple")
		obj.set_attrib("ai.target", null)
		obj.set_attrib("wandering", true)
		return
		
	if player.get_attrib("animation.in_movement") == true:
		BehaviorEvents.emit_signal("OnWaitForAnimation")
		player.set_attrib("animation.waiting_moving", true)
		obj.set_attrib("ap.ai_acted", true) # hack to make the AI exit without using it's turn
		return
		
	var player_tile = Globals.LevelLoaderRef.World_to_Tile(player.position)
	var obj_tile = Globals.LevelLoaderRef.World_to_Tile(obj.position)
	var weapons = obj.get_attrib("mounts.weapon")
	var modified_attributes = obj.get_attrib("mount_attributes.weapon")
	var weapons_data = Globals.LevelLoaderRef.LoadJSONArray(weapons)
	#if weapons_data != null and weapons_data.size() > 0
	
	var cur_difficulty : int = PermSave.get_attrib("settings.difficulty")
	var diff_chance_mult : float = 1.0
	diff_chance_mult = (4.0 - cur_difficulty) / 2.0
	
	var minimal_move = null
	var shot = false
	BehaviorEvents.emit_signal("OnBeginParallelAction", obj)
	for index in range(weapons_data.size()):
		var data = weapons_data[index]
		var attrib_data = modified_attributes[index]
		var best_move = _targetting.ClosestFiringSolution(obj_tile, player_tile, data)
		var is_destroyed = player.get_attrib("destroyable.destroyed")
		if best_move.length() == 0 and (is_destroyed == null or is_destroyed == false):
			var chance = obj.get_attrib("ai.hit_chance")
			chance = 1.0 - (diff_chance_mult * (1.0 - chance))
			if chance == null or MersenneTwister.rand_float() < chance:
				BehaviorEvents.emit_signal("OnDealDamage", [player], obj, data, attrib_data, player_tile)
			else:
				var log_choices = {
					"The enemy missed":50,
					"Enemy shot wide!":50,
					"The enemy can't shoot a fish in a barrel!":5,
					"Evasive maneuver beta two successful!":30,
					"Evasive maneuver beta nine successful!":30,
					"Evasive pattern gamma six successful!":30,
					"Evasive pattern delta successful!":30,
					"Evasive pattern lambda ten successful!":30,
					"Evasive maneuver omega three successful!":30,
					"Evasive sequence 010 successful!":10,
					"Evasive sequence beta four successful!":10,
					"That was a close one!":5,
					"Evasive maneuver gamma one successful!":30,
					"Evasive pattern sigma ten successful!":30,
					"Evasive sequence delta detla successful!":10,
					"Evasive maneuver pi alpha two successful!":5,
					"Evasive pattern Riker successful!":1,
					"Evasive pattern Kirk Epsilon successful!":1
				}
				BehaviorEvents.emit_signal("OnLogLine", log_choices)
				 # play the animation but no damage
				BehaviorEvents.emit_signal("OnShotFired", player_tile, obj, data)
				var fire_speed = Globals.get_data(data, "weapon_data.fire_speed")
				var speed_mult = Globals.EffectRef.GetMultiplierValue(obj, data.src, attrib_data, "fire_speed_multiplier")
				BehaviorEvents.emit_signal("OnUseAP", obj, fire_speed * speed_mult)
			shot = true
		if minimal_move == null or minimal_move.length() > best_move.length():
			minimal_move = best_move
	BehaviorEvents.emit_signal("OnEndParallelAction", obj)

	if shot == false:
		var move_by = Vector2(0, 0)
		move_by.x = clamp(minimal_move.x, -1, 1)
		move_by.y = clamp(minimal_move.y, -1, 1)
		BehaviorEvents.emit_signal("OnMovement", obj, move_by)

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
	var scary_pos := Vector2(0.0, 0.0)
	if from_id != null:
		scary_pos = from_id.position
	my_pos = Globals.LevelLoaderRef.World_to_Tile(my_pos)
	scary_pos = Globals.LevelLoaderRef.World_to_Tile(scary_pos)
	var scanner_range = 0
	var scanner = obj.get_attrib("mounts.scanner")
	var scanner_json = null
	if scanner != null:
		scanner_json = scanner[0]
	if scanner_json != null and scanner_json != "":
		var scanner_data = Globals.LevelLoaderRef.LoadJSON(scanner_json)
		scanner_range = scanner_data.scanning.radius
	var distance = my_pos - scary_pos
	if distance.length_squared() >= scanner_range * scanner_range:
		obj.set_attrib("ai.unseen_for", obj.get_attrib("ai.unseen_for") + 1)
	
	if obj.get_attrib("ai.unseen_for") > obj.get_attrib("ai.stop_running_after"):
		#TODO: Maybe wrap this in a method too ?
		obj.modified_attributes.ai.erase("pathfinding")
		obj.modified_attributes.ai.erase("run_from")
		obj.modified_attributes.ai.erase("unseen_for")
		obj.modified_attributes.erase("wandering")
		BehaviorEvents.emit_signal("OnUseAP", obj, 1.0)
		return
		
		
	if distance.length_squared() <= 0:
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
	
	
	

