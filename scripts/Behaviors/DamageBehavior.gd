extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnDealDamage", self, "OnDealDamage_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	
func OnObjectLoaded_Callback(obj):
	if obj.get_attrib("harvestable") == null:
		return
	
	var min_rich = obj.get_attrib("harvestable.min_rich")
	var max_rich = obj.get_attrib("harvestable.max_rich")
	var min_rate = obj.get_attrib("harvestable.min_base_rate")
	var max_rate = obj.get_attrib("harvestable.max_base_rate")
	obj.modified_attributes["harvestable"] = {}
	obj.set_attrib("harvestable.count", MersenneTwister.rand(max_rich-min_rich) + min_rich)
	obj.set_attrib("harvestable.chance", (MersenneTwister.rand_float() * (max_rate-min_rate)) + min_rate)
	
func OnDealDamage_Callback(target, shooter, weapon_data):
	if validate_action(target, shooter, weapon_data) == true:
		BehaviorEvents.emit_signal("OnShotFired", target, shooter, weapon_data)
		if target.get_attrib("harvestable") != null:
			ProcessHarvesting(target, shooter, weapon_data)
		else:
			ProcessDamage(target, shooter, weapon_data)
	
func validate_action(target, shooter, weapon_data):
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
				ammo_ok = true
				item.count -= 1
				shooter.set_attrib("cargo.volume_used", shooter.get_attrib("cargo.volume_used") - ammo_data.equipment.volume)
	
	if not ammo_ok && is_player:
		BehaviorEvents.emit_signal("OnLogLine", "No more " + ammo_data.name_id + " to shoot")
		return false
	
	if "fire_energy_cost" in weapon_data.weapon_data:
		BehaviorEvents.emit_signal("OnUseEnergy", shooter, weapon_data.weapon_data.fire_energy_cost)
	if "fire_speed" in weapon_data.weapon_data:
		BehaviorEvents.emit_signal("OnUseAP", shooter, weapon_data.weapon_data.fire_speed)
		
	return true
		
	
	
func ProcessHarvesting(target, shooter, weapon_data):
	
	var is_player = shooter.get_attrib("type") == "player"
	var is_target_player = target.get_attrib("type") == "player"
	var item_left = target.get_attrib("harvestable.count")
	#TODO modulate chance based on weapon data
	var chance = target.get_attrib("harvestable.chance")
	var item_json = target.get_attrib("harvestable.drop")
	var drop_count = 0
	for i in range(item_left):
		if MersenneTwister.rand_float() < chance:
			drop_count += 1
	if drop_count == 0 && is_player:
		BehaviorEvents.emit_signal("OnLogLine", "Your shots did not produce anything useful")
	else:
		for i in range(drop_count):
			var x = MersenneTwister.rand(3) - 1
			var y = MersenneTwister.rand(3) - 1
			var offset = Vector2(x,y)
			Globals.LevelLoaderRef.RequestObject(item_json, Globals.LevelLoaderRef.World_to_Tile(target.position) + offset)
		target.modified_attributes.harvestable.count -= drop_count
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
		var shield_name = target.get_attrib("mounts.shield")
		var shield_data = null
		if shield_name != null and shield_name != "":
			shield_data = Globals.LevelLoaderRef.LoadJSON(shield_name)
		var dam_absorbed_by_shield = _hit_shield(target, dam, shield_data)
		var hull_dam = dam - dam_absorbed_by_shield
		target.set_attrib("destroyable.hull", target.get_attrib("destroyable.hull") - hull_dam)
		if target.get_attrib("destroyable.hull") <= 0:
			if target.get_attrib("drop_on_death") != null:
				ProcessDeathSpawns(target)
			if is_player:
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
		if MersenneTwister.rand_float() < stuff.chance:
			Globals.LevelLoaderRef.RequestObject(stuff.id, Globals.LevelLoaderRef.World_to_Tile(target.position))
	
func _hit_shield(target, dam, shield_data):
	if shield_data == null or dam == 0:
		return 0
		
	var cur_hp = target.get_attrib("shield.current_hp")
	if cur_hp == null:
		cur_hp = shield_data.shielding.max_hp
	
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
