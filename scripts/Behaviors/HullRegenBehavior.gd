extends Node


func _ready():
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnConsumeItem", self, "OnConsumeItem_Callback")
	
	
func OnObjTurn_Callback(obj):
	var regen_data = obj.get_attrib("consumable.hull_regen")
	if regen_data == null:
		return
	
	var finished = []
	var index = 0
	for active_item in regen_data:
		var item_data = Globals.LevelLoaderRef.LoadJSON(active_item.data)
		active_item = _process_healing(obj, active_item, item_data)
		var turn_since_beginning = active_item.last_turn_update - active_item.first_turn
		if item_data.hull_regen.duration >= 0 and turn_since_beginning >= item_data.hull_regen.duration:
			finished.push_back(index)
		index += 1
		
	if finished.size() == regen_data.size():
		obj.modified_attributes.consumable.erase("hull_regen")
	else:
		for v in finished:
			regen_data.remove(v)
		# probably not needed if array is passed as ref... just in case
		obj.set_attrib("consumable.hull_regen", regen_data)
	
	#TODO: do the same thing in consume event in case consumable last only 1 turn
		

func _process_healing(obj, data, item_data):
	if not "last_turn_update" in data:
		data["last_turn_update"] = Globals.total_turn-1.0
		
	if not "first_turn" in data:
		data["first_turn"] = Globals.total_turn-1.0
	
	var last_update = data.last_turn_update
	
	var turn_count = Globals.total_turn - last_update
	var turn_since_beginning = Globals.total_turn - data.first_turn
	if item_data.hull_regen.duration >= 0 and turn_since_beginning > item_data.hull_regen.duration:
		turn_count = (Globals.total_turn - data.first_turn) - item_data.hull_regen.duration
	
	var heal = 0.0
	if turn_count > 0.0:
		heal = item_data.hull_regen.point_per_turn * turn_count
		var max_hull = obj.get_attrib("destroyable.hull")
		var cur_hull = obj.get_attrib("destroyable.current_hull", max_hull)
		var new_hull = min(max_hull, cur_hull + heal)
		obj.set_attrib("destroyable.current_hull", new_hull)
		if new_hull <= 0:
			obj.set_attrib("destroyable.damage_source", "Radiation")
			obj.set_attrib("destroyable.destroyed", true) # so other systems can check if their reference is valid or not
			if obj.get_attrib("type") == "player":
				BehaviorEvents.emit_signal("OnPlayerDeath", obj)
			BehaviorEvents.emit_signal("OnObjectDestroyed", obj)
			BehaviorEvents.emit_signal("OnRequestObjectUnload", obj)
		elif heal < 0:
			BehaviorEvents.emit_signal("OnDamageTaken", obj, null, Globals.DAMAGE_TYPE.radiation)
		
	
	data.last_turn_update = Globals.total_turn
	return data
	
	
func OnConsumeItem_Callback(obj, item_data):
	if not "hull_regen" in item_data:
		return
		
	BehaviorEvents.emit_signal("OnLogLine", "[color=yelllow]Nanites deployed ![/color]")
	
	var regen_data = obj.get_attrib("consumable.hull_regen")
	if regen_data == null:
		regen_data = []
	
	# Do one update right away, hence the -1.0 to total_turn
	var cur_data = {"data":item_data.src, "last_turn_update": Globals.total_turn-1.0, "first_turn": Globals.total_turn-1.0}
	cur_data = _process_healing(obj, cur_data, item_data)
	
	# don't need to keep updating if consumable is instant
	if item_data.hull_regen.duration > 1.0:
		regen_data.push_back(cur_data)
		obj.set_attrib("consumable.hull_regen", regen_data)
	
	
