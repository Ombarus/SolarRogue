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
	obj.set_attrib("harvestable.count", int((randf() * (max_rich-min_rich)) + min_rich))
	obj.set_attrib("harvestable.chance", (randf() * (max_rate-min_rate)) + min_rate)
	
func OnDealDamage_Callback(target, shooter, weapon_data):
	if target.get_attrib("harvestable") != null:
		ProcessHarvesting(target, shooter, weapon_data)
	else:
		ProcessDamage(target, shooter, weapon_data)
	
func ProcessHarvesting(target, shooter, weapon_data):
	var ammo = null
	var is_player = shooter.get_attrib("type") == "player"
	if weapon_data.weapon_data.has("ammo"):
		ammo = weapon_data.weapon_data.ammo
	var ammo_ok = false
	var ammo_data = null
	if ammo == null:
		ammo_ok = true
	if ammo != null && shooter.get_attrib("cargo"):
		ammo_data = Globals.LevelLoaderRef.LoadJSON(ammo)
		for item in shooter.get_attrib("cargo.content"):
			if item.src == ammo && item.count > 0:
				ammo_ok = true
				item.count -= 1
	
	if not ammo_ok && is_player:
		BehaviorEvents.emit_signal("OnLogLine", "No more " + ammo_data.name_id + " to shoot")
		return
	
	var item_left = target.get_attrib("harvestable.count")
	#TODO modulate chance based on weapon data
	var chance = target.get_attrib("harvestable.chance")
	var item_json = target.get_attrib("harvestable.drop")
	var drop_count = 0
	for i in range(item_left):
		if randf() < chance:
			drop_count += 1
	if drop_count == 0 && is_player:
		BehaviorEvents.emit_signal("OnLogLine", "Your shots did not produce anything useful")
	else:
		for i in range(drop_count):
			var x = int(randf() * 3) - 1
			var y = int(randf() * 3) - 1
			var offset = Vector2(x,y)
			Globals.LevelLoaderRef.RequestObject(item_json, Globals.LevelLoaderRef.World_to_Tile(target.position) + offset)
		target.modified_attributes.harvestable.count -= drop_count
		if is_player:
			BehaviorEvents.emit_signal("OnLogLine", "Some useful materials float into orbit")
	
	
func ProcessDamage(target, shooter, weapon_data):
	var min_dam = weapon_data.weapon_data.base_dam
	var max_dam = weapon_data.weapon_data.max_dam
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
			if item.src == ammo && item.count > 0:
				ammo_ok = true
				item.count -= 1
				shooter.set_attrib("cargo.volume_used", shooter.get_attrib("cargo.volume_used") - ammo_data.equipment.volume)
	
	if not ammo_ok && is_player:
		BehaviorEvents.emit_signal("OnLogLine", "No more " + ammo_data.name_id + " to shoot")
		return
		
	var dam = int((randf() * (max_dam-min_dam)) + min_dam)
	if dam == 0 && is_player:
		BehaviorEvents.emit_signal("OnLogLine", "Shot missed")
	else:
		target.set_attrib("destroyable.hull", target.get_attrib("destroyable.hull") - dam)
		if target.get_attrib("destroyable.hull") <= 0:
			if is_player:
				BehaviorEvents.emit_signal("OnLogLine", "[color=red]You destroy the ennemy ![/color]")
			if is_target_player:
				BehaviorEvents.emit_signal("OnPlayerDeath")
			BehaviorEvents.emit_signal("OnRequestObjectUnload", target)
		else:
			if is_player:
				BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]You do " + str(dam) + " damage[/color]")
		BehaviorEvents.emit_signal("OnDamageTaken", target, shooter)
	
		
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
