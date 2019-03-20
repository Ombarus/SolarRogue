extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnDealDamage", self, "OnDealDamage_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	
	
func sort_by_chance(a, b):
	if a.chance > b.chance:
		return true
	return false
	
	
func OnObjectLoaded_Callback(obj):
	# if harvestable.inventory is set then we are loading a savegame and we don't need to init the planet's data
	if obj.get_attrib("harvestable") == null or obj.get_attrib("harvestable.inventory") != null:
		return
	
	var inv_size = obj.get_attrib("harvestable.inventory_size")
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
	modified_harvestable_data["has_defense"] = MersenneTwister.rand_float() <= defense_chance
	
	obj.set_attrib("harvestable", modified_harvestable_data)
	
	#if modified_harvestable_data["has_defense"] == true:
	#	var pondered_ennemies = obj.get_attrib("harvestable.pondered_defense_list")
	#	pondered_ennemies.sort_custom(self, "sort_by_chance")
		
	
	#obj.modified_attributes["harvestable"] = {}
	#obj.set_attrib("harvestable.count", MersenneTwister.rand(max_rich-min_rich) + min_rich)
	#obj.set_attrib("harvestable.chance", (MersenneTwister.rand_float() * (max_rate-min_rate)) + min_rate)
	
	
func OnDealDamage_Callback(target, shooter, weapon_data):
	if validate_action(target, shooter, weapon_data) == true:
		BehaviorEvents.emit_signal("OnShotFired", target, shooter, weapon_data)
		if target.get_attrib("harvestable") != null:
			ProcessHarvesting(target, shooter, weapon_data)
		else:
			ProcessDamage(target, shooter, weapon_data)
	
	
func validate_action(target, shooter, weapon_data):
	var defense_deployed = target.get_attrib("harvestable.defense_deployed")
	if defense_deployed != null and defense_deployed == true:
		BehaviorEvents.emit_signal("OnLogLine", "This planet has a colony, let's not push our luck.")
		return false
		
	var ammo = null
	var is_player = shooter.get_attrib("type") == "player"
	var is_target_player = target.get_attrib("type") == "player"
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
				BehaviorEvents.emit_signal("OnRemoveItem", shooter, item.src)
				ammo_ok = true
	
	if not ammo_ok && is_player:
		BehaviorEvents.emit_signal("OnLogLine", "No more " + ammo_data.name_id + " to shoot")
		return false
	
	if "fire_energy_cost" in weapon_data.weapon_data:
		BehaviorEvents.emit_signal("OnUseEnergy", shooter, weapon_data.weapon_data.fire_energy_cost)
	if "fire_speed" in weapon_data.weapon_data:
		BehaviorEvents.emit_signal("OnUseAP", shooter, weapon_data.weapon_data.fire_speed)
		
	return true
		
	
	
func ProcessHarvesting(target, shooter, weapon_data):
	if target.get_attrib("harvestable.has_defense") == true:
		ProcessDefense(target, shooter, weapon_data)
	else:
		ProcessHarvest(target, shooter, weapon_data)
		
		
func ProcessDefense(target, shooter, weapon_data):
	var defense_size = target.get_attrib("harvestable.defense_size")
	var pondered_ennemies = target.get_attrib("harvestable.pondered_defense_list")
	pondered_ennemies.sort_custom(self, "sort_by_chance")
	
	var max_pond = 0
	for item in pondered_ennemies:
		max_pond += item.chance
	
	var spawn_count = MersenneTwister.rand(defense_size[1]-defense_size[0]) + defense_size[0]
	var ennemies_to_spawn = []
	for i in range(spawn_count):
		var roll = MersenneTwister.rand(max_pond)
		var selected_item = null
		var sum = 0
		for item in pondered_ennemies:
			if sum + item.chance > roll:
				selected_item = item.src
				break
			sum += item.chance
		ennemies_to_spawn.push_back(selected_item)
		
	var bounds = Globals.LevelLoaderRef.levelSize
	for json in ennemies_to_spawn:
		var x = MersenneTwister.rand(3) - 1
		var y = MersenneTwister.rand(3) - 1
		var tile = Globals.LevelLoaderRef.World_to_Tile(target.position)
		x = clamp(tile.x + x, 0, bounds.x-1)
		y = clamp(tile.y + y, 0, bounds.y-1)
		var offset = Vector2(x,y)
		Globals.LevelLoaderRef.RequestObject(json, offset)
		
	BehaviorEvents.emit_signal("OnLogLine", "[color=red]This planet had a colony and they are NOT happy. They've deployed defenses.[/color]")
	target.set_attrib("harvestable.defense_deployed", true)
	
	
func ProcessHarvest(target, shooter, weapon_data):
	#TODO modulate chance based on weapon data
	var chance = target.get_attrib("harvestable.actual_rate")
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
		for inv_index in drop_index_list:
			var x = MersenneTwister.rand(3) - 1
			var y = MersenneTwister.rand(3) - 1
			var tile = Globals.LevelLoaderRef.World_to_Tile(target.position)
			x = clamp(tile.x + x, 0, bounds.x-1)
			y = clamp(tile.y + y, 0, bounds.y-1)
			var offset = Vector2(x,y)
			Globals.LevelLoaderRef.RequestObject(inventory[inv_index], offset)
			# safe because we're going from last to first so the next index shouldn't change
			inventory.remove(inv_index)
		if is_player:
			BehaviorEvents.emit_signal("OnLogLine", "Some useful materials float into orbit")


func ProcessDamage(target, shooter, weapon_data):
	var is_player = shooter.get_attrib("type") == "player"
	var is_target_player = target.get_attrib("type") == "player"
	var min_dam = weapon_data.weapon_data.base_dam
	var max_dam = weapon_data.weapon_data.max_dam
	
	var dam = MersenneTwister.rand(max_dam-min_dam) + min_dam
	if dam == 0:
		if is_player:
			BehaviorEvents.emit_signal("OnLogLine", "Shot missed")
		elif is_target_player:
			BehaviorEvents.emit_signal("OnLogLine", "The ennemy missed")
	else:
		var dam_absorbed_by_shield = _hit_shield(target, dam)
		var hull_dam = dam - dam_absorbed_by_shield
		target.set_attrib("destroyable.hull", target.get_attrib("destroyable.hull") - hull_dam)
		if target.get_attrib("destroyable.hull") <= 0:
			target.set_attrib("destroyable.destroyed", true) # so other systems can check if their reference is valid or not
			if target.get_attrib("drop_on_death") != null:
				ProcessDeathSpawns(target)
			if is_player:
				if target.get_attrib("boardable") == true:
					BehaviorEvents.emit_signal("OnLogLine", "[color=red]You destroyed one of YOUR ship ![/color]")
				else:
					BehaviorEvents.emit_signal("OnLogLine", "[color=red]You destroy the ennemy ![/color]")
			if is_target_player:
				BehaviorEvents.emit_signal("OnPlayerDeath")
			BehaviorEvents.emit_signal("OnObjectDestroyed", target)
			BehaviorEvents.emit_signal("OnRequestObjectUnload", target)
		else:
			if is_player:
				BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]You do " + str(dam) + " damage[/color]")
			elif is_target_player:
				BehaviorEvents.emit_signal("OnLogLine", "[color=red]You take " + str(dam) + " damage[/color]")
		BehaviorEvents.emit_signal("OnDamageTaken", target, shooter)
	
	
func ProcessDeathSpawns(target):
	for stuff in target.get_attrib("drop_on_death"):
		var spawned = Globals.LevelLoaderRef.GetGlobalSpawn(stuff.id)
		var can_spawn = not "global_max" in stuff or stuff["global_max"] < spawned
		if can_spawn and MersenneTwister.rand_float() < stuff.chance:
			Globals.LevelLoaderRef.RequestObject(stuff.id, Globals.LevelLoaderRef.World_to_Tile(target.position))


func _hit_shield(target, dam):
	var cur_hp = target.get_attrib("shield.current_hp")
	if cur_hp == null or cur_hp <= 0:
		return 0
	
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
