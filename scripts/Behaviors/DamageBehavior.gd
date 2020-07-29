extends Node

var _waiting_for_anim = false

func _ready():
	BehaviorEvents.connect("OnDealDamage", self, "OnDealDamage_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnObjectDestroyed", self, "OnObjectDestroyed_Callback")
	
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	
	
func OnWaitForAnimation_Callback():
	_waiting_for_anim = true
	
func OnAnimationDone_Callback():
	_waiting_for_anim = false
	
func sort_by_chance(a, b):
	if a.chance > b.chance:
		return true
	return false
	
	
func OnObjectLoaded_Callback(obj):
	# if harvestable.inventory is set then we are loading a savegame and we don't need to init the planet's data
	if obj.get_attrib("harvestable") == null or obj.get_attrib("harvestable.inventory") != null:
		return
		
		
	var cur_difficulty : int = PermSave.get_attrib("settings.difficulty")
	var diff_inv_bonus : int = 0.0
	# arbitrary, should be tweaked (at diff 0 (normal), min inventory + 4, diff of impossible, min inventory - 4)
	diff_inv_bonus = 4 - (cur_difficulty*2)
	
	var inv_size = obj.get_attrib("harvestable.inventory_size")
	inv_size[0] = max(0, inv_size[0]+diff_inv_bonus)
	inv_size[1] = max(0, inv_size[1]+(diff_inv_bonus*1.5))
	
	var rate = obj.get_attrib("harvestable.base_rate")
	var defense_chance = obj.get_attrib("harvestable.defense_chance")
	#var defense_size = obj.get_attrib("harvestable.defense_size")
	var pondered_inv = obj.get_attrib("harvestable.pondered_inventory_content")
	pondered_inv.sort_custom(self, "sort_by_chance")
	
	var modified_harvestable_data = {}
	var actual_inv_size = MersenneTwister.rand(inv_size[1]-inv_size[0]) + inv_size[0]
	modified_harvestable_data["actual_rate"] = (MersenneTwister.rand_float() * (rate[1]-rate[0])) + rate[0]
	var max_pond_inv = 0
	for item in pondered_inv:
		max_pond_inv += item.chance
	
	var actual_inv = []
	for i in range(actual_inv_size):
		var target = MersenneTwister.rand(max_pond_inv)
		var selected_item = null
		var sum = 0
		for item in pondered_inv:
			if sum + item.chance > target:
				selected_item = item.src
				break
			sum += item.chance
		actual_inv.push_back(selected_item)
		
	modified_harvestable_data["inventory"] = actual_inv
	modified_harvestable_data["actual_inventory_size"] = actual_inv_size
	modified_harvestable_data["has_defense"] = MersenneTwister.rand_float() <= defense_chance
	
	obj.set_attrib("harvestable", modified_harvestable_data)
	
	#if modified_harvestable_data["has_defense"] == true:
	#	var pondered_enemies = obj.get_attrib("harvestable.pondered_defense_list")
	#	pondered_enemies.sort_custom(self, "sort_by_chance")
		
	
	#obj.modified_attributes["harvestable"] = {}
	#obj.set_attrib("harvestable.count", MersenneTwister.rand(max_rich-min_rich) + min_rich)
	#obj.set_attrib("harvestable.chance", (MersenneTwister.rand_float() * (max_rate-min_rate)) + min_rate)
	
	
func OnDealDamage_Callback(targets, shooter, weapon_data, shot_tile):
	var shot_fired := false
	for target in targets:
		if validate_action(target, shooter, weapon_data) == true:
			if shot_fired == false:
				shot_fired = true
				# Should only be triggered once per weapon, but needs to happen before we send event for destroyed ship
				# otherwise we don't know we need to wait for the animation of the shot
				BehaviorEvents.emit_signal("OnShotFired", shot_tile, shooter, weapon_data)
			if target.get_attrib("harvestable") != null:
				ProcessHarvesting(target, shooter, weapon_data)
			else:
				ProcessDamage(target, shooter, weapon_data)
	if targets.empty() and Globals.get_data(weapon_data, "weapon_data.shoot_empty", false) == true:
		if validate_action(null, shooter, weapon_data) == true:
			shot_fired = true
			var log_choices = {
				"Scans report no hit sir!":80,
				"Critical Miss sir!":1,
				"We're not even shooting at air sir!":50,
				"Energy wasted for nothing!":10,
				"Too bad, better luck next time captain!":5
			}
			BehaviorEvents.emit_signal("OnLogLine", log_choices)
			BehaviorEvents.emit_signal("OnShotFired", shot_tile, shooter, weapon_data)
	if shot_fired == true:
		consume(shooter, weapon_data)
	
func consume(shooter, weapon_data):
	if "fire_energy_cost" in weapon_data.weapon_data:
		var cost : float = weapon_data.weapon_data.fire_energy_cost * _get_power_amplifier_stack(shooter, "energy_percent")
		BehaviorEvents.emit_signal("OnUseEnergy", shooter, cost)
	if "fire_speed" in weapon_data.weapon_data:
		BehaviorEvents.emit_signal("OnUseAP", shooter, weapon_data.weapon_data.fire_speed)
	
	var ammo = null
	if weapon_data.weapon_data.has("ammo"):
		ammo = weapon_data.weapon_data.ammo
		
	if ammo == null:
		return null
	if shooter.get_attrib("cargo") != null:
		shooter.init_cargo()
		for item in shooter.get_attrib("cargo.content"):
			if ammo in item.src && item.count > 0:
				BehaviorEvents.emit_signal("OnRemoveItem", shooter, item.src, item.get("modified_attributes", {}))
				
	
	
func validate_action(target, shooter, weapon_data):
	if target != null:
		var defense_deployed = target.get_attrib("harvestable.defense_deployed")
		if defense_deployed != null and defense_deployed == true:
			var log_choices = {
				"This planet has a colony, let's not push our luck":150,
				"Shooting a colonized world is a bit mean, even for us captain!":50,
				"I respectfully disagree captain!":50,
				"Shooting a colonized world is against regulation":150,
				"We've done enough damaged for now":50,
				"You... monster!":1
			}
			BehaviorEvents.emit_signal("OnLogLine", log_choices)
			return false
			
		if Globals.is_(target.get_attrib("destroyable.destroyed"), true):
			return false
		
	var ammo = null
	var is_player = shooter.get_attrib("type") == "player"
	if weapon_data.weapon_data.has("ammo"):
		ammo = weapon_data.weapon_data.ammo
	
	var ammo_ok = false
	var ammo_data = null
	if ammo == null:
		ammo_ok = true
	if ammo != null && shooter.get_attrib("cargo"):
		if not shooter.modified_attributes.has("cargo"):
			shooter.init_cargo()
		ammo_data = Globals.LevelLoaderRef.LoadJSON(ammo)
		for item in shooter.get_attrib("cargo.content"):
			if ammo in item.src && item.count > 0:
				#BehaviorEvents.emit_signal("OnRemoveItem", shooter, item.src)
				ammo_ok = true
	
	if not ammo_ok && is_player:
		var log_choices = {
			"No more %s to shoot":50,
			"Our Holds don't hold any %s":10,
			"We need %s":50,
			"Sir! we should craft more %s":50,
			"Will do sir! as soon as the converter makes more %s!":20
		}
		BehaviorEvents.emit_signal("OnLogLine", log_choices, [Globals.mytr(ammo_data.name_id)])
		return false
	
	#if "fire_energy_cost" in weapon_data.weapon_data:
	#	BehaviorEvents.emit_signal("OnUseEnergy", shooter, weapon_data.weapon_data.fire_energy_cost)
	#if "fire_speed" in weapon_data.weapon_data:
	#	BehaviorEvents.emit_signal("OnUseAP", shooter, weapon_data.weapon_data.fire_speed)
		
	return true
		
	
	
func ProcessHarvesting(target, shooter, weapon_data):
	if target.get_attrib("harvestable.has_defense") == true:
		ProcessDefense(target, shooter, weapon_data)
	else:
		ProcessHarvest(target, shooter, weapon_data)
		
		
func ProcessDefense(target, shooter, weapon_data):
	var defense_size = target.get_attrib("harvestable.defense_size")
	var pondered_enemies = target.get_attrib("harvestable.pondered_defense_list")
	pondered_enemies.sort_custom(self, "sort_by_chance")
	
	var max_pond = 0
	for item in pondered_enemies:
		max_pond += item.chance
	
	var spawn_count = MersenneTwister.rand(defense_size[1]-defense_size[0]) + defense_size[0]
	var enemies_to_spawn = []
	for i in range(spawn_count):
		var roll = MersenneTwister.rand(max_pond)
		var selected_item = null
		var sum = 0
		for item in pondered_enemies:
			if sum + item.chance > roll:
				selected_item = item.src
				break
			sum += item.chance
		enemies_to_spawn.push_back(selected_item)
		
	var bounds = Globals.LevelLoaderRef.levelSize
	for json in enemies_to_spawn:
		var x = MersenneTwister.rand(3) - 1
		var y = MersenneTwister.rand(3) - 1
		var tile = Globals.LevelLoaderRef.World_to_Tile(target.position)
		x = clamp(tile.x + x, 0, bounds.x-1)
		y = clamp(tile.y + y, 0, bounds.y-1)
		var offset = Vector2(x,y)
		var modified_attrib : Dictionary = {"action_point":1}
		
		BehaviorEvents.emit_signal("OnAddToAnimationQueue", Globals.LevelLoaderRef, "RequestObject", [json, offset, modified_attrib], 500)
		#Globals.LevelLoaderRef.RequestObject(json, offset, modified_attrib)
	
	var log_choices = {
		"[color=red]This planet had a colony and they are NOT happy. They've deployed defenses.[/color]":100,
		"[color=red]Oops! I guess someone was living here. They've deployed planetary defenses![/color]":20,
		"[color=red]Ships inbound! This planet is defended![/color]":100,
		"[color=red]We really should look at the planet's description before shooting...":1
	}
	BehaviorEvents.emit_signal("OnAddToAnimationQueue", BehaviorEvents, "emit_signal", ["OnLogLine", log_choices], 500)
	#BehaviorEvents.emit_signal("OnLogLine", "[color=red]This planet had a colony and they are NOT happy. They've deployed defenses.[/color]")
	target.set_attrib("harvestable.defense_deployed", true)
	BehaviorEvents.emit_signal("OnDamageTaken", target, shooter, Globals.DAMAGE_TYPE.hull_hit)
	
	
func ProcessHarvest(target, shooter, weapon_data):
	#TODO modulate chance based on weapon data
	var chance = target.get_attrib("harvestable.actual_rate")
	var bonus_chance = Globals.get_data(weapon_data, "weapon_data.planet_bonus", 0.0)
	chance = chance + bonus_chance
	var drop_index_list = []
	var inventory = target.get_attrib("harvestable.inventory")
	for i in range(inventory.size()):
		var should_drop = MersenneTwister.rand_float() <= chance
		if should_drop == true:
			# NOTICE THE PUSH ***FRONT*** SO WE LATER CAN DELETE WHILE WE ITERATE ON THE ARRAY !
			drop_index_list.push_front(i)

	var is_player = shooter.get_attrib("type") == "player"	
	if drop_index_list.size() == 0 && is_player:
		BehaviorEvents.emit_signal("OnLogLine", "Your shots did not produce anything useful")
	else:
		var bounds = Globals.LevelLoaderRef.levelSize
		
		var modif_data = null
		# Mark as seen so that goto doesn't interrupt for items we're sure to have seen before
		if is_player:
			modif_data = {"memory": {"was_seen_by":true}}
			
		for inv_index in drop_index_list:
			var x = MersenneTwister.rand(3) - 1
			var y = MersenneTwister.rand(3) - 1
			var tile = Globals.LevelLoaderRef.World_to_Tile(target.position)
			x = clamp(tile.x + x, 0, bounds.x-1)
			y = clamp(tile.y + y, 0, bounds.y-1)
			var offset = Vector2(x,y)
			BehaviorEvents.emit_signal("OnAddToAnimationQueue", Globals.LevelLoaderRef, "RequestObject", [inventory[inv_index], offset, modif_data], 500)
			#Globals.LevelLoaderRef.RequestObject(inventory[inv_index], offset)
			# safe because we're going from last to first so the next index shouldn't change
			inventory.remove(inv_index)
		target.set_attrib("harvestable.actual_inventory_size", inventory.size())
		if is_player:
			BehaviorEvents.emit_signal("OnAddToAnimationQueue", BehaviorEvents, "emit_signal", ["OnLogLine", "Some useful materials float into orbit"], 500)
			#BehaviorEvents.emit_signal("OnLogLine", "Some useful materials float into orbit")

	BehaviorEvents.emit_signal("OnDamageTaken", target, shooter, Globals.DAMAGE_TYPE.hull_hit)


func ProcessDamage(target, shooter, weapon_data):
	var is_player = shooter.get_attrib("type") == "player"
	var is_target_player = target.get_attrib("type") == "player"
	var min_dam = weapon_data.weapon_data.base_dam
	var max_dam = weapon_data.weapon_data.max_dam
	
	var dam = MersenneTwister.rand(max_dam-min_dam) + min_dam
	dam = dam * _get_power_amplifier_stack(shooter, "damage_percent")
	if dam == 0:
		if is_player:
			BehaviorEvents.emit_signal("OnLogLine", "Shot missed")
		elif is_target_player:
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
	else:
		var dam_absorbed_by_shield = _hit_shield(target, dam, weapon_data)
		var hull_dam = dam - dam_absorbed_by_shield
		var max_hull = target.get_attrib("destroyable.hull")
		target.set_attrib("destroyable.current_hull", target.get_attrib("destroyable.current_hull", max_hull) - hull_dam)
		if target.get_attrib("destroyable.current_hull") <= 0:
			target.set_attrib("destroyable.destroyed", true) # so other systems can check if their reference is valid or not
			if is_player:
				if target.get_attrib("boardable") == true:
					BehaviorEvents.emit_signal("OnLogLine", "[color=red]You destroyed one of YOUR ship ![/color]")
				else:
					var log_choices = {
						"[color=red]You destroy the enemy ![/color]":50,
						"[color=red]Boum![/color]":10,
						"[color=red]The shot pierce the Hull and ignite the warp core creating a very pretty explosion![/color]":50,
						"[color=red]A direct hit to the main deck creates a chain reaction in the onboard computer and ends in a firework![/color]":20,
						"[color=red]Their life support is down, enemy destroyed![/color]":50,
						"[color=red]Your shot cuts the enemy in half![/color]":50,
						"[color=red]A few escape pod manage to launch from the enemy ship before it loses it's remaining integrity![/color]":50,
						"[color=red]The enemy ship proceed to execute a rapid unscheduled disassembly![/color]":5,
						"[color=red]Hull breach detected in level 1 to 100. All system shutdown. Terminated![/color]":20,
						"[color=red]Ixnay on the starship![/color]":15,
						"[color=red]Fire are spreading throught the ship, explosion imminent![/color]":50,
						"[color=red]Victory is ours captain![/color]":50,
						"[color=red]We've hit the exhaust port and created a chain reaction that reached the reactor core![/color]":2,
						"[color=red]Reactor core critical, enemy destroyed![/color]":50,
						"[color=red]The enemy ship self-destructed![/color]":20,
					}
					BehaviorEvents.emit_signal("OnLogLine", log_choices)
			if is_target_player:
				BehaviorEvents.emit_signal("OnPlayerDeath")
			if shooter is Attributes:
				target.set_attrib("destroyable.destroyer", shooter.get_attrib("unique_id"))
			BehaviorEvents.emit_signal("OnObjectDestroyed", target)
			BehaviorEvents.emit_signal("OnRequestObjectUnload", target)
		else:
			if is_player:
				BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]You do %d damage[/color]", [dam])
			elif is_target_player:
				var param = [dam]
				var log_choices = {
					"[color=red]You take %d damage[/color]":100
				}
				if hull_dam > 0:
					log_choices = {
						"[color=red]You take %d damage[/color]":50,
						"[color=red]Deck 3 to 4 report %s hull damage![/color]":50,
						"[color=red]Deck 9 and 10 report %s hull damage![/color]":50,
						"[color=red]Deck 1 to 5 report %s hull damage![/color]":50,
						"[color=red]Hull integrity down by %s points![/color]":50,
						"[color=red]Engineering bay hit for %s damage![/color]":50,
						"[color=red]Medbay hit for %s damage![/color]":50,
						"[color=red]Concourse C hit for %s damage![/color]":50,
						"[color=red]Concourse A hit for %s damage![/color]":50,
						"[color=red]%s damage, we've lost the external nacelle 1! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 2! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 3! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 4! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 5! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 6! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 7! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 8! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 9! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 10! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 11! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 12! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 13! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 14! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 15! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 16! Good thing it's useless.[/color]":10,
						"[color=red]%s damage, we've lost the external nacelle 42! Good thing it's useless.[/color]":1,
						"[color=red]Hull integrity down %s. Repair team dispatched to deck 10[/color]":30,
						"[color=red]Hull integrity down %s. Repair team dispatched to deck 12[/color]":30,
						"[color=red]Hull integrity down %s. Repair team dispatched to deck 4[/color]":30,
						"[color=red]System integrity down %s points, redirecting power to auxilary conduit![/color]":50,
						"[color=red]Primary system down, switching to auxilary power![/color]":1
					}
				else:
					var cur_shield = target.get_attrib("shield.current_hp")
					var max_shield = target.get_max_shield()
					var shield_per = stepify(cur_shield / max_shield * 100.0, 0.1)
					param = [shield_per]
					log_choices = {
						"[color=red]Shield holding at %s%%![/color]":50,
						"[color=red]Main deflector shield at %s%%![/color]":50,
						"[color=red]We've been hit! Shield at %s%%![/color]":50,
						"[color=red]Our shield won't hold forever! Shield at %s%%![/color]":10,
						"[color=red]No damage! Shield at %s%%![/color]":30
					}
				BehaviorEvents.emit_signal("OnLogLine", log_choices, param)
		target.set_attrib("destroyable.damage_source", shooter.get_attrib("name_id"))
		
		var damage_type = Globals.DAMAGE_TYPE.shield_hit
		if hull_dam > 0:
			damage_type = Globals.DAMAGE_TYPE.hull_hit
		
		BehaviorEvents.emit_signal("OnDamageTaken", target, shooter, damage_type)
	
func OnObjectDestroyed_Callback(target):
	if target.get_attrib("drop_on_death") != null:
		BehaviorEvents.emit_signal("OnAddToAnimationQueue", self, "ProcessDeathSpawns", [target], 500)
		#ProcessDeathSpawns(target)
	
func ProcessDeathSpawns(target):
	var destroyer = Globals.LevelLoaderRef.GetObjectById(target.get_attrib("destroyable.destroyer"))
	var modif_data = null
	# Mark as seen so that goto doesn't interrupt for items we're sure to have seen before
	if destroyer != null and destroyer.get_attrib("type") == "player":
		modif_data = {"memory": {"was_seen_by":true}}
	for stuff in target.get_attrib("drop_on_death"):
		var spawned = Globals.LevelLoaderRef.GetGlobalSpawn(stuff.id)
		var can_spawn = not "global_max" in stuff or stuff["global_max"] < spawned
		if can_spawn and MersenneTwister.rand_float() < stuff.chance:
			Globals.LevelLoaderRef.RequestObject(stuff.id, Globals.LevelLoaderRef.World_to_Tile(target.position), modif_data)

func _get_power_amplifier_stack(shooter, type):
	var utilities : Array = shooter.get_attrib("mounts.utility", [])
	var utilities_data : Array = Globals.LevelLoaderRef.LoadJSONArray(utilities)
	
	var power_amp := []
	for data in utilities_data:
		var boost = Globals.get_data(data, "damage_boost." + type)
		if boost != null:
			power_amp.push_back(boost / 100.0) # displayed as percentage, we want a fraction
			
	if power_amp.size() <= 0:
		return 1.0
	
	power_amp.sort()
	power_amp.invert()
	var max_boost := 0.0
	var count := 0
	for val in power_amp:
		max_boost += val / pow(2, count) # 1, 0.5, 0.25, 0.125, etc.
		count += 1
		
	return max_boost

func _hit_shield(target, dam, weapon_data):
	var cur_hp = target.get_attrib("shield.current_hp")
	if cur_hp == null or cur_hp <= 0:
		return 0
		
	var shield_penetration : float = Globals.get_data(weapon_data, "weapon_data.shield_penetration", 0.0) / 100.0
	dam = dam - (dam * shield_penetration)
	
	var new_hp = max(0, cur_hp - dam)
	var absorbed = dam
	if new_hp <= 0:
		absorbed = cur_hp
	
	target.set_attrib("shield.current_hp", new_hp)
	return absorbed

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
