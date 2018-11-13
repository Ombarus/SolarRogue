extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnPickup", self, "OnPickup_Callback")
	
func OnPickup_Callback(picker, picked):
	var picked_obj = []
	if typeof(picked) == TYPE_VECTOR2:
		picked_obj = Globals.LevelLoaderRef.levelTiles[picked.x][picked.y]
	elif picked is Node:
		picked_obj = [picked]
		
	var filtered_obj = []
	for obj in picked_obj:
		if obj.base_attributes.has("equipment"):
			filtered_obj.push_back(obj)
			
	if filtered_obj.size() <= 0 && picker.base_attributes.type == "player":
		BehaviorEvents.emit_signal("OnLogLine", "The tractor beam failed to lock on")
		return
		
	if not picker.modified_attributes.has("cargo"):
		picker.modified_attributes["cargo"] = {}
		picker.modified_attributes.cargo["content"] = picker.base_attributes.cargo.content
		picker.modified_attributes.cargo["capacity"] = picker.base_attributes.cargo.capacity
	var inventory_space = picker.modified_attributes.cargo.capacity
	for obj in filtered_obj:
		if obj.base_attributes.equipment.volume > inventory_space:
			if picker.base_attributes.type == "player":
				BehaviorEvents.emit_signal("OnLogLine", "Cannot pick up " + obj.base_attributes.name_id	+ " Cargo holds are full")
			continue
		picker.modified_attributes.cargo.capacity -= obj.base_attributes.equipment.volume
		if picker.base_attributes.type == "player":
				BehaviorEvents.emit_signal("OnLogLine", "Tractor beam has brought " + obj.base_attributes.name_id + " abord")
		if obj.base_attributes.equipment.stackable:
			var found = false
			for item in picker.modified_attributes.cargo.content:
				if item.src == obj.base_attributes.src:
					found = true
					item.count += 1
			if not found:
				picker.modified_attributes.cargo.content.push_back({"src": obj.base_attributes.src, "count":1})
		else:
			picker.modified_attributes.cargo.content.push_back({"src": obj.base_attributes.src, "count":1})
		BehaviorEvents.emit_signal("OnRequestObjectUnload", obj)
		obj = null
	filtered_obj.clear() # the objects have been destroyed, just want to make sure I don't forget about it
	
	
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
