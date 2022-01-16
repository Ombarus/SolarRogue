extends Node

var _cached_anomalies := {}

func _ready():
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnTriggerAnomaly", self, "OnTriggerAnomaly_Callback")
	
	
func OnLevelLoaded_Callback():
	_cached_anomalies = {} # reset anomaly cache
	if not "anomaly" in Globals.LevelLoaderRef.objByType:
		return
	var anomalies : Array = Globals.LevelLoaderRef.objByType["anomaly"]
	for anomaly in anomalies:
		var tile = Globals.LevelLoaderRef.World_to_Tile(anomaly.position)
		if not tile.x in _cached_anomalies:
			_cached_anomalies[tile.x] = {}
		var player : Attributes = Globals.LevelLoaderRef.objByType["player"][0]
		var anomaly_id = anomaly.get_attrib("unique_id")
		var level_id = Globals.LevelLoaderRef.GetLevelID()
		var known_anomalies = player.get_attrib("scanner_result.known_anomalies." + level_id)
		var detected : bool = false
		if known_anomalies != null and anomaly_id in known_anomalies:
			detected = known_anomalies[anomaly_id]
		anomaly.visible = detected
		#WARNING: don't want more than one anomaly for a given tile. But it *could* happen ? maybe ?
		# The way this will work is that only one anomaly will be registered and the other ones will be ignored
		_cached_anomalies[tile.x][tile.y] = anomaly
	
	
func OnObjTurn_Callback(obj):
	var effect_list = obj.get_attrib("anomaly.effects")
	if effect_list != null and effect_list.size() > 0:
		update_effect(obj, effect_list)
	var tile = Globals.LevelLoaderRef.World_to_Tile(obj.position)
	if not tile.x in _cached_anomalies or not tile.y in _cached_anomalies[tile.x]:
		return
		
	BehaviorEvents.emit_signal("OnTriggerAnomaly", obj, _cached_anomalies[tile.x][tile.y])


func OnTriggerAnomaly_Callback(obj, anomaly):
	var is_player = obj.get_attrib("type") == "player"
	if is_player:
		var anomaly_id = anomaly.get_attrib("unique_id")
		var level_id = Globals.LevelLoaderRef.GetLevelID()
		var known_anomalies = obj.get_attrib("scanner_result.known_anomalies." + level_id)
		if known_anomalies == null:
			known_anomalies = {}
		known_anomalies[anomaly_id] = true
		obj.set_attrib("scanner_result.known_anomalies." + level_id, known_anomalies)
		anomaly.visible = true
		
	var effect_info = anomaly.get_attrib("anomaly.speed")
	if effect_info != null:
		#TODO: add fx
		var moving_data : float = obj.get_attrib("moving.speed")
		if moving_data != null:
			var special_speed_mult = max(effect_info.multiplier, obj.get_attrib("moving.special_multiplier", 0))
			obj.set_attrib("moving.special_multiplier", special_speed_mult)
			var already_exist = add_to_ongoing_effect(obj, effect_info, "speed")
			if is_player and not already_exist:
				#TODO: change text to be dynamic based on special_speed_mult
				BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]The anomaly has corrupted your warp drives, engine at half power[/color]")	
				
	effect_info = anomaly.get_attrib("anomaly.energy")
	if effect_info != null:
		var amount : float = Globals.get_data(effect_info, "amount", 0)
		var duration = Globals.get_data(effect_info, "duration_turn")
		var already_exist = add_to_ongoing_effect(obj, effect_info, "energy")
		if not already_exist and (duration == null or duration <= 0):
			BehaviorEvents.emit_signal("OnUseEnergy", obj, -amount)
		elif not already_exist:
			obj.set_attrib("converter.extra_ap_energy_cost", -amount)
		if is_player and not already_exist:
			if amount < 0:
				BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]The anomaly is syphoning energy from the ship ![/color]")
			else:
				BehaviorEvents.emit_signal("OnLogLine", "[color=lime]The anomaly was full of free energy, we're gaining energy ![/color]")
				
	effect_info = anomaly.get_attrib("anomaly.scanner")
	if effect_info != null:
		var amount : int = Globals.get_data(effect_info, "range_bonus")
		var cur_bonus : int = obj.get_attrib("scanner_result.range_bonus", 0)
		var already_exist = add_to_ongoing_effect(obj, effect_info, "scanner")
		if not already_exist:
			obj.set_attrib("scanner_result.range_bonus", cur_bonus + amount)
			if is_player:
				if amount < 0:
					BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]A magnetic pulse from the Anomaly has disabled our scanners ![/color]")
				else:
					BehaviorEvents.emit_signal("OnLogLine", "[color=lime]The anomaly resonate with our scanners giving them a boost ![/color]")

		
func add_to_ongoing_effect(obj, effect_info, type):
	var current_effects = obj.get_attrib("anomaly.effects", [])
	var existing_data = null
	for f_data in current_effects:
		if f_data.type == type:
			existing_data = f_data
			break
	
	var duration = Globals.get_data(effect_info, "duration_turn")
	if duration == null:
		return
	
	if existing_data == null:
		var effect_data = str2var(var2str(effect_info))
		if duration == 0:
			effect_data["duration_turn"] = 1.0 # give a cooldown so the effect doesn't re-trigger every fraction of a turn
		effect_data["type"] = type
		effect_data["last_turn_update"] = Globals.total_turn
		var obj_effect_list = obj.get_attrib("anomaly.effects", [])
		obj_effect_list.push_back(effect_data)
		obj.set_attrib("anomaly.effects", obj_effect_list)
	else:
		existing_data["duration_turn"] = max(duration, existing_data["duration_turn"])
		existing_data["last_turn_update"] = Globals.total_turn
		
	return existing_data != null
	
	
func update_effect(obj, effect_list):
	var to_clear = []
	for effect in effect_list:
		if "duration_turn" in effect:
			effect.duration_turn -= Globals.total_turn - effect.last_turn_update
			effect.last_turn_update = Globals.total_turn
		
		if not "duration_turn" in effect or effect.duration_turn <= 0:
			remove_effect(obj, effect)
			to_clear.push_back(effect)
				
	for effect in to_clear:
		effect_list.erase(effect)
		
	obj.set_attrib("anomaly.effects", effect_list)

func remove_effect(obj, effect):
	if effect.type == "speed":
		var moving_data = obj.get_attrib("moving")
		moving_data.erase("special_multiplier")
		obj.set_attrib("moving", moving_data)
		if obj.get_attrib("type") == "player":
			BehaviorEvents.emit_signal("OnLogLine", "[color=lime]Purge complete, all system back online[/color]")
	if effect.type == "energy":
		var converter_data = obj.get_attrib("converter")
		if "extra_ap_energy_cost" in converter_data:
			converter_data.erase("extra_ap_energy_cost")
			obj.set_attrib("converter", converter_data)
			if obj.get_attrib("type") == "player":
				BehaviorEvents.emit_signal("OnLogLine", "[color=lime]The energy Syphon has subsided[/color]")
	if effect.type == "scanner":
		var amount : int = Globals.get_data(effect, "range_bonus")
		var prev_bonus : int = obj.get_attrib("scanner_result.range_bonus")
		obj.set_attrib("scanner_result.range_bonus", prev_bonus - amount)
		if obj.get_attrib("type") == "player":
			BehaviorEvents.emit_signal("OnLogLine", "[color=lime]Scanners are back to normal[/color]")
			
	BehaviorEvents.emit_signal("OnAnomalyEffectGone", obj, effect)

