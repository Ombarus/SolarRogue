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
			BehaviorEvents.emit_signal("OnLogLine", "Some useful material float into orbit")
	
	
func ProcessDamage(target, shooter, weapon_data):
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
