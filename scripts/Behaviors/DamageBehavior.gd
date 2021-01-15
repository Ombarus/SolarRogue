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
	
	
func OnDealDamage_Callback(targets, shooter, weapon_data, modified_attributes, shot_tile):
	var shot_fired := false
	for target in targets:
		if validate_action(target, shooter, weapon_data, modified_attributes) == true:
			if shot_fired == false:
				shot_fired = true
				# Should only be triggered once per weapon, but needs to happen before we send event for destroyed ship
				# otherwise we don't know we need to wait for the animation of the shot
				BehaviorEvents.emit_signal("OnShotFired", shot_tile, shooter, weapon_data)
			if target.get_attrib("harvestable") != null:
				ProcessHarvesting(target, shooter, weapon_data)
			else:
				ProcessDamage(target, shooter, weapon_data, modified_attributes)
	if targets.empty() and Globals.get_data(weapon_data, "weapon_data.shoot_empty", false) == true:
		if validate_action(null, shooter, weapon_data, modified_attributes) == true:
			shot_fired = true
			var log_choices = {
				"Scans report no hit sir!":150,
				"Critical Miss sir!":10,
				"We're not even shooting at air sir!":50,
				"Energy wasted for nothing!":20,
				"Too bad, better luck next time captain!":10,
				"Ensign Kim messed up the launch tubes again!":1
			}
			BehaviorEvents.emit_signal("OnLogLine", log_choices)
			BehaviorEvents.emit_signal("OnShotFired", shot_tile, shooter, weapon_data)
	if shot_fired == true:
		consume(shooter, weapon_data, modified_attributes)
	
func consume(shooter, weapon_data, modified_attributes):
	if "fire_energy_cost" in weapon_data.weapon_data:
		var energy_mult = Globals.EffectRef.GetMultiplierValue(shooter, weapon_data.src, modified_attributes, "fire_energy_cost_multiplier")
		var cost : float = weapon_data.weapon_data.fire_energy_cost #* _get_power_amplifier_stack(shooter, "energy_percent")
		BehaviorEvents.emit_signal("OnUseEnergy", shooter, cost * energy_mult)
	if "fire_speed" in weapon_data.weapon_data:
		var speed_mult = Globals.EffectRef.GetMultiplierValue(shooter, weapon_data.src, modified_attributes, "fire_speed_multiplier")
		BehaviorEvents.emit_signal("OnUseAP", shooter, weapon_data.weapon_data.fire_speed * speed_mult)
	if "cooldown" in weapon_data.weapon_data:
		Globals.EffectRef.SetCooldown(shooter, modified_attributes, weapon_data.weapon_data.cooldown)
	
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
				
	
	
func validate_action(target, shooter, weapon_data, modified_attributes):
	if shooter.get_attrib("offline_systems.weapon", 0.0) > 0.0:
		BehaviorEvents.emit_signal("OnLogLine", "[color=red]Weapon System Offline![/color]")
		return false
		
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
		#TODO: will ammo have variations/effect? if so, need to pass modified_attrib here
		BehaviorEvents.emit_signal("OnLogLine", log_choices, [Globals.EffectRef.get_display_name(ammo_data, {})])
		return false
		
	
	if "fire_energy_cost" in weapon_data.weapon_data:
		var energy_mult = Globals.EffectRef.GetMultiplierValue(shooter, weapon_data.src, modified_attributes, "fire_energy_cost_multiplier")
		var cost : float = weapon_data.weapon_data.fire_energy_cost #* _get_power_amplifier_stack(shooter, "energy_percent")
		cost = cost * energy_mult
		var cur_energy = shooter.get_attrib("converter.stored_energy", cost+1)
		if cur_energy < cost:
			if is_player == true:
				BehaviorEvents.emit_signal("OnLogLine", "[color=red]Not enough energy to power weapons![/color]")
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


func ProcessDamage(target, shooter, weapon_data, modified_attributes):
	var is_player = shooter.get_attrib("type") == "player"
	var is_target_player = target.get_attrib("type") == "player"
	var min_dam_mult = Globals.EffectRef.GetMultiplierValue(shooter, weapon_data.src, modified_attributes, "base_dam_multiplier")
	var max_dam_mult = Globals.EffectRef.GetMultiplierValue(shooter, weapon_data.src, modified_attributes, "max_dam_multiplier")
	var min_dam = weapon_data.weapon_data.base_dam * min_dam_mult
	var max_dam = weapon_data.weapon_data.max_dam * max_dam_mult
	
	var cur_difficulty : int = PermSave.get_attrib("settings.difficulty")
	var diff_chance_mult : float = 1.0
	diff_chance_mult = -1.0 / 4.0 * cur_difficulty + 1.5
	
	var ai_malus : float = shooter.get_attrib("ai.hit_chance_malus", 0.0) * diff_chance_mult
	var chance : float = Globals.get_data(weapon_data, "weapon_data.base_hit_chance", 1.0)
	var effect_bonus : float = Globals.EffectRef.GetBonusValue(shooter, weapon_data.src, modified_attributes, "hit_chance_bonus")
	var dodge_bonus : float = Globals.EffectRef.GetBonusValue(target, weapon_data.src, null, "dodge_chance_bonus")
	var electro_success := false
	chance = chance - ai_malus + effect_bonus - dodge_bonus
	chance = clamp(chance, 0.1, 1.0) # minimum 10% chance always because I say so!
	var dam := 0.0
	if chance == null or MersenneTwister.rand_float() < chance:
		electro_success = true
		dam = MersenneTwister.rand(max_dam-min_dam) + min_dam
		#dam = dam * _get_power_amplifier_stack(shooter, "damage_percent")
		
	var is_critical := false
	var hull_dam = 0.0
	var shield_per = 100.0
	
	if dam > 0:
		var crit_chance = Globals.get_data(weapon_data, "weapon_data.crit_chance", 0.0)
		var bonus_crit = Globals.EffectRef.GetBonusValue(shooter, weapon_data.src, modified_attributes, "crit_chance_bonus")
		if MersenneTwister.rand_float() < crit_chance + bonus_crit:
			dam = dam * Globals.get_data(weapon_data, "weapon_data.crit_multiplier", 1.0)
			is_critical = true
			
		var aegis_conversion = _aegis_conversion(target, dam)
		if aegis_conversion > 0:
			var cur_shield = target.get_attrib("shield.current_hp")
			var max_shield = target.get_max_shield()
			if cur_shield + aegis_conversion > max_shield:
				aegis_conversion = max_shield - cur_shield
			target.set_attrib("shield.current_hp", cur_shield + aegis_conversion)
			BehaviorEvents.emit_signal("OnDamageTaken", target, null, Globals.DAMAGE_TYPE.shield_hit)
			if is_target_player:
				BehaviorEvents.emit_signal("OnLogLine", "[color=lime]The Aegis Shield reacts to the shot and regenerate %d points![/color]", [aegis_conversion])
			return
			
		var dam_absorbed_by_shield = _hit_shield(target, dam, shooter, weapon_data, modified_attributes)
		var hull_dam_mult : float = Globals.EffectRef.GetMultiplierValue(shooter, weapon_data.src, modified_attributes, "dam_hull_multiplier")
		hull_dam = dam - dam_absorbed_by_shield
		hull_dam *= hull_dam_mult
		var max_hull = target.get_attrib("destroyable.hull")
		target.set_attrib("destroyable.current_hull", target.get_attrib("destroyable.current_hull", max_hull) - hull_dam)
		target.set_attrib("destroyable.damage_source", shooter.get_attrib("name_id"))
		if target.get_attrib("destroyable.current_hull") <= 0:
			target.set_attrib("destroyable.destroyed", true) # so other systems can check if their reference is valid or not
			if is_target_player:
				BehaviorEvents.emit_signal("OnPlayerDeath", target)
			if shooter is Attributes:
				target.set_attrib("destroyable.destroyer", shooter.get_attrib("unique_id"))
			BehaviorEvents.emit_signal("OnObjectDestroyed", target)
			BehaviorEvents.emit_signal("OnRequestObjectUnload", target)
		elif is_target_player and hull_dam <= 0.0:
			var cur_shield = target.get_attrib("shield.current_hp")
			var max_shield = target.get_max_shield()
			shield_per = stepify(cur_shield / max_shield * 100.0, 0.1)
		
		var damage_type = Globals.DAMAGE_TYPE.shield_hit
		if hull_dam > 0:
			damage_type = Globals.DAMAGE_TYPE.hull_hit
		
		BehaviorEvents.emit_signal("OnDamageTaken", target, shooter, damage_type)
		
	if electro_success and target.get_attrib("destroyable.destroyed", false) == false:
		_handle_electronic_warfare(target, shooter, weapon_data, modified_attributes)
	
	display_damage_log(is_player, is_target_player, dam, hull_dam, shield_per, target.get_attrib("destroyable.current_hull", target.get_attrib("destroyable.hull")) <= 0, is_critical, target.get_attrib("boardable", false))
	
func _handle_electronic_warfare(target, shooter, weapon_data, modified_attributes):
	var is_player = shooter.get_attrib("type") == "player"
	var weapon_detail = weapon_data.get("weapon_data", {})
	var weapon_keys : Array = weapon_detail.keys()
	var warfare_choices := []
	for key in weapon_keys:
		if ("destroy_" in key or "disable_" in key or "take_ship" in key) and not "duration" in key:
			#TODO: Add bonus/malus effects from variations and utilities
			warfare_choices.push_back({
				"name_id":key, 
				"chance":weapon_detail[key], 
				"target":target, "shooter":shooter, 
				"duration_min":weapon_detail.get("disable_duration_min", 0), # optional, default 0
				"duration_max":weapon_detail.get("disable_duration_max", 0)
			})
			
	if warfare_choices.size() > 1:
		if is_player:
			BehaviorEvents.emit_signal("OnPushGUI", "HackTarget", {"callback_object":self, "callback_method":"apply_warfare_choice", "targets":warfare_choices})
			shooter.set_attrib("wait_for_hack", true)
		else:
			# make a choice for the AI
			#TODO: this is to test shield disabling, make the AI choose randomly?
			for line in warfare_choices:
				if "ship" in line.name_id:
					apply_warfare_choice([line])
					break
	elif warfare_choices.size() == 1:
		apply_warfare_choice(warfare_choices)
	
func apply_warfare_choice(selected_targets):
	var target : Attributes = selected_targets[0].target
	var shooter : Attributes = selected_targets[0].shooter
	var action : String = selected_targets[0].name_id
	var chance : float = selected_targets[0].chance
	var duration_min : int = selected_targets[0].duration_min
	var duration_max : int = selected_targets[0].duration_max
	
	if MersenneTwister.rand_float() < chance:
		if "disable_" in action:
			var disable_turn : int = MersenneTwister.rand(duration_max - duration_min) + duration_min
			var part : String = action.replace("disable_", "").replace("_chance", "")
			var previous_timer : float = target.get_attrib("offline_systems.%s" % part, 0.0)
			disable_turn = max(disable_turn, previous_timer)
			target.set_attrib("offline_systems.%s" % part, disable_turn)
			if previous_timer <= 0.0: # only trigger disable if we weren't already disabled
				BehaviorEvents.emit_signal("OnSystemDisabled", target, part)
	if shooter.get_attrib("wait_for_hack", false) == true:
		shooter.set_attrib("wait_for_hack", false)
		BehaviorEvents.emit_signal("OnResumeAttack")
	
	
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
	var global_chance_mult = Globals.EffectRef.GetMultiplierValue(destroyer, destroyer.get_attrib("name_id"), {}, "drop_chance_multiplier")
	for stuff in target.get_attrib("drop_on_death"):
		var spawned = Globals.LevelLoaderRef.GetGlobalSpawn(stuff.id)
		var can_spawn = not "global_max" in stuff or stuff["global_max"] < spawned
		if can_spawn and MersenneTwister.rand_float() < (stuff.chance * global_chance_mult):
			Globals.LevelLoaderRef.RequestObject(stuff.id, Globals.LevelLoaderRef.World_to_Tile(target.position), modif_data)


func _aegis_conversion(target, dam) -> float:
	var shields = target.get_attrib("mounts.shield")
	var shields_data = Globals.LevelLoaderRef.LoadJSONArray(shields)
	for shield_data in shields_data:
		var conversion_chance : float = Globals.get_data(shield_data, "shielding.damage_conversion", 0.0)
		if conversion_chance > 0.0:
			var conv_roll : float = MersenneTwister.rand_float()
			if conv_roll < conversion_chance:
				return dam
	return 0.0

func _hit_shield(target, dam, shooter, weapon_data, modified_attributes):
	var cur_hp = target.get_attrib("shield.current_hp")
	if cur_hp == null or cur_hp <= 0:
		return 0
		
	var shield_penetration : float = Globals.get_data(weapon_data, "weapon_data.shield_penetration", 0.0) / 100.0
	var shield_dam_mult : float = Globals.EffectRef.GetMultiplierValue(shooter, weapon_data.src, modified_attributes, "dam_shield_multiplier")
	dam = dam - (dam * shield_penetration)
	dam *= shield_dam_mult
	
	var new_hp = max(0, cur_hp - dam)
	var absorbed = dam
	if new_hp <= 0:
		absorbed = cur_hp
	
	target.set_attrib("shield.current_hp", new_hp)
	# remove the bonus from EM damage since the result will be used to calculate hull damage.
	return absorbed / shield_dam_mult

func display_damage_log(player_shooter : bool, 
	player_target : bool, 
	dam : float,
	hull_dam : float,
	shield_per : float,
	is_destroyed : bool, 
	is_critical : bool, 
	boardable : bool):
		
	var txt
	var fmt : Array = []
	
	var player_crit_choices := {
		"[color=aqua]C[/color][color=blue]R[/color][color=fuchsia]I[/color][color=gray]T[/color][color=green]I[/color][color=lime]C[/color][color=maroon]A[/color][color=navy]L[/color] [color=purple]H[/color][color=silver]I[/color][color=teal]T[/color][color=red]![/color]":150,
		"[color=red]BOUMSHAKALAKA![/color]":5,
		"[color=red]FINISH HIM![/color]":5,
		"[color=red]OUCH! RIGHT IN THE KESTREL[/color]":1,
		"[color=red]FATALITY!!![/color]":5,
		"[color=red]That was one in a million kid![/color]":1,
		"[color=red]That exhaust port was a bad design![/color]":1
	}
	var enemy_crit_choices := {
		"[color=red]They found our weak point![/color]":50,
		"[color=aqua]C[/color][color=blue]R[/color][color=fuchsia]I[/color][color=gray]T[/color][color=green]I[/color][color=lime]C[/color][color=maroon]A[/color][color=navy]L[/color] [color=purple]H[/color][color=silver]I[/color][color=teal]T[/color][color=red]![/color]":50,
		"[color=red]They're attack was very effective![/color]":1,
		"[color=red]They got a lucky shot![/color]":5
	}
		
	var player_miss_choices := {
		"Shot missed":50,
		"Shot went wide":50,
		"Enemy evaded our shot":50,
		"Lucky miss":5,
		"Grazing hit, no damage":15
	}
	
	var enemy_miss_choices := {
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
	
	var enemy_destroyed_choices := {
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
	
	var boardable_destroyed := "[color=red]You destroyed one of YOUR ship ![/color]"

	var player_hull_dam_choices := {
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
	
	var player_shield_dam_choices = {
		"[color=red]Shield holding at %s%%![/color]":50,
		"[color=red]Main deflector shield at %s%%![/color]":50,
		"[color=red]We've been hit! Shield at %s%%![/color]":50,
		"[color=red]Our shield won't hold forever! Shield at %s%%![/color]":10,
		"[color=red]No damage! Shield at %s%%![/color]":30
	}
	
	var player_hit_enemy = "[color=yellow]You do %d damage[/color]"
	
	var player_destroyed = {
		"[color=red]Your ship has been destroyed![/color]":50,
		"[color=red]Your ship blows up![/color]":50,
		"[color=red]System Critical, abandon ship![/color]":50,
		"[color=red]This is the end![/color]":50,
		"[color=red]All things must pass![/color]":50,
		"[color=red]Better luck next time![/color]":20,
		"[color=red]Ashes to ashes, dust to dust![/color]":10,
		"[color=red]You kick the bucket![/color]":10,
		"[color=red]Another one bite the dust![/color]":4,
		"[color=red]Old soldiers never die, they simply fade away![/color]":4,
		"[color=red]Hasta la vista, baby![/color]":1
	}
	
	if is_critical:
		if player_shooter:
			txt = player_crit_choices
		if player_target:
			txt = enemy_crit_choices
		
		BehaviorEvents.emit_signal("OnLogLine", txt, fmt)
	
	fmt = []
	if player_shooter and dam == 0:
		txt = player_miss_choices
	if player_target and dam == 0:
		txt = enemy_miss_choices
	if player_target and hull_dam > 0.0:
		txt = player_hull_dam_choices
		fmt = [dam]
	if player_target and hull_dam <= 0.0 and dam > 0.0:
		txt = player_shield_dam_choices
		fmt = [shield_per]
	if player_shooter and dam > 0:
		txt = player_hit_enemy
		fmt = [dam]

	BehaviorEvents.emit_signal("OnLogLine", txt, fmt)
	
	fmt = []
	if is_destroyed:
		if player_shooter and is_destroyed and not boardable:
			txt = enemy_destroyed_choices
		elif player_shooter and boardable:
			txt = boardable_destroyed
		elif player_target and is_destroyed:
			txt = player_destroyed
			
		BehaviorEvents.emit_signal("OnLogLine", txt, fmt)
