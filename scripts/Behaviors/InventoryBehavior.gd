extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnPickup", self, "OnPickup_Callback")
	
	
func OnPickup_Callback(picker, picked):
	var picked_obj = []
	var is_player = picker.get_attrib("type") == "player"
	if typeof(picked) == TYPE_VECTOR2:
		picked_obj = Globals.LevelLoaderRef.levelTiles[picked.x][picked.y]
	elif picked is Node:
		picked_obj = [picked]
		
	var filtered_obj = []
	for obj in picked_obj:
		if obj.get_attrib("equipment") != null:
			filtered_obj.push_back(obj)
			
	if filtered_obj.size() <= 0 && is_player:
		BehaviorEvents.emit_signal("OnLogLine", "The tractor beam failed to lock on")
		return
		
	if not picker.modified_attributes.has("cargo"):
		picker.init_cargo()
	var inventory_space = picker.get_attrib("cargo.capacity") - picker.get_attrib("cargo.volume_used")
	for obj in filtered_obj:
		if obj.get_attrib("equipment.volume") > inventory_space:
			if is_player:
				BehaviorEvents.emit_signal("OnLogLine", "Cannot pick up " + obj.get_attrib("name_id") + " Cargo holds are full")
			continue
		picker.set_attrib("cargo.volume_used", picker.get_attrib("cargo.volume_used") + obj.get_attrib("equipment.volume"))
		inventory_space -= obj.get_attrib("equipment.volume")
		if is_player:
				BehaviorEvents.emit_signal("OnLogLine", "Tractor beam has brought " + obj.get_attrib("name_id") + " abord")
		if obj.get_attrib("equipment.stackable"):
			var found = false
			for item in picker.get_attrib("cargo.content"):
				if item.src in obj.get_attrib("src"):
					found = true
					item.count += 1
			if not found:
				picker.get_attrib("cargo.content").push_back({"src": obj.base_attributes.src, "count":1})
		else:
			picker.get_attrib("cargo.content").push_back({"src": obj.base_attributes.src, "count":1})
		BehaviorEvents.emit_signal("OnRequestObjectUnload", obj)
		obj = null
	filtered_obj.clear() # the objects have been destroyed, just want to make sure I don't forget about it
	
	
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
