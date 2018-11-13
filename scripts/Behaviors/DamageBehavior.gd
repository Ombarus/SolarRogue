extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnDealDamage", self, "OnDealDamage_Callback")
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	
func OnObjectLoaded_Callback(obj):
	if not obj.base_attributes.has("harvestable"):
		return
	
	var min_rich = obj.base_attributes.harvestable.min_rich
	var max_rich = obj.base_attributes.harvestable.max_rich
	var min_rate = obj.base_attributes.harvestable.min_base_rate
	var max_rate = obj.base_attributes.harvestable.max_base_rate
	obj.modified_attributes["harvestable"] = {}
	obj.modified_attributes["harvestable"]["count"] = int((randf() * (max_rich-min_rich)) + min_rich)
	obj.modified_attributes["harvestable"]["chance"] = (randf() * (max_rate-min_rate)) + min_rate
	
func OnDealDamage_Callback(target, shooter, weapon_data):
	if target.base_attributes.has("harvestable"):
		ProcessHarvesting(target, shooter, weapon_data)
	else:
		ProcessDamage(target, shooter, weapon_data)
	
func ProcessHarvesting(target, shooter, weapon_data):
	var ammo = null
	if weapon_data.weapon_data.has("ammo"):
		ammo = weapon_data.weapon_data.ammo
	var ammo_ok = false
	var ammo_data = null
	if ammo == null:
		ammo_ok = true
	if ammo != null && shooter.base_attributes.has("cargo"):
		ammo_data = Globals.LevelLoaderRef.LoadJSON(ammo)
		for item in shooter.base_attributes.cargo.content:
			if item.src == ammo && item.count > 0:
				ammo_ok = true
				item.count -= 1
	
	if not ammo_ok && shooter.base_attributes.type == "player":
		BehaviorEvents.emit_signal("OnLogLine", "No more " + ammo_data.name_id + " to shoot")
		return
	
	var item_left = target.modified_attributes.harvestable.count
	#TODO modulate chance based on weapon data
	var chance = target.modified_attributes.harvestable.chance
	var item_json = target.base_attributes.harvestable.drop
	var drop_count = 0
	for i in range(item_left):
		if randf() < chance:
			drop_count += 1
	if drop_count == 0 && shooter.base_attributes.type == "player":
		BehaviorEvents.emit_signal("OnLogLine", "Your shots did not produce anything useful")
	else:
		for i in range(drop_count):
			var x = int(randf() * 3) - 1
			var y = int(randf() * 3) - 1
			var offset = Vector2(x,y)
			Globals.LevelLoaderRef.RequestObject(item_json, Globals.LevelLoaderRef.World_to_Tile(target.position) + offset)
		target.modified_attributes.harvestable.count -= drop_count
		if shooter.base_attributes.type == "player":
			BehaviorEvents.emit_signal("OnLogLine", "Some useful materials float into orbit")
	
	
func ProcessDamage(target, shooter, weapon_data):
	var min_dam = weapon_data.weapon_data.base_dam
	var max_dam = weapon_data.weapon_data.max_dam
	var ammo = null
	if weapon_data.weapon_data.has("ammo"):
		ammo = weapon_data.weapon_data.ammo
	
	var ammo_ok = false
	var ammo_data = null
	if ammo == null:
		ammo_ok = true
	if ammo != null && shooter.base_attributes.has("cargo"):
		if not shooter.modified_attributes.has("cargo"):
			shooter.modified_attributes["cargo"] = {}
			shooter.modified_attributes.cargo["content"] = shooter.base_attributes.cargo.content
			shooter.modified_attributes.cargo["capacity"] = shooter.base_attributes.cargo.capacity
		ammo_data = Globals.LevelLoaderRef.LoadJSON(ammo)
		for item in shooter.modified_attributes.cargo.content:
			if item.src == ammo && item.count > 0:
				ammo_ok = true
				item.count -= 1
				shooter.modified_attributes.cargo.capacity += ammo_data.equipment.volume
	
	if not ammo_ok && shooter.base_attributes.type == "player":
		BehaviorEvents.emit_signal("OnLogLine", "No more " + ammo_data.name_id + " to shoot")
		return
		
	var dam = int((randf() * (max_dam-min_dam)) + min_dam)
	if dam == 0 && shooter.base_attributes.type == "player":
		BehaviorEvents.emit_signal("OnLogLine", "Shot missed")
	else:
		if not target.modified_attributes.has("destroyable"):
			target.modified_attributes["destroyable"] = {}
			target.modified_attributes.destroyable["hull"] = target.base_attributes.destroyable.hull
		target.modified_attributes.destroyable.hull -= dam
		if target.modified_attributes.destroyable.hull <= 0:
			if shooter.base_attributes.type == "player":
				BehaviorEvents.emit_signal("OnLogLine", "[color=red]You destroy the ennemy ![/color]")
			BehaviorEvents.emit_signal("OnRequestObjectUnload", target)
		else:
			if shooter.base_attributes.type == "player":
				BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]You do " + str(dam) + " damage[/color]")
	
		
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
