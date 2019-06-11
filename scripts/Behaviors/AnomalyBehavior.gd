extends Node

var _cached_anomalies := {}

func _ready():
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnTriggerAnomaly", self, "OnTriggerAnomaly_Callback")
	
	
func OnLevelLoaded_Callback():
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
			#QUESTION: can anomaly stack ? what if you pass multiple time on the same anomaly ?
			#QUESTION: should slow affect only movement or all actions (including crafting, shooting, etc, ?)
			obj.set_attrib("moving.special_multiplier", effect_info.multiplier)
			add_to_ongoing_effect(obj, effect_info, "speed")
			if is_player:
				#TODO: check if there's already an active effect of same type ?
				BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]The anomaly has corrupted your warp drives, engine at half power[/color]")
	
	effect_info = anomaly.get_attrib("anomaly.energy")
	if effect_info != null:
		var amount : float = Globals.get_data(effect_info, "amount")
		if amount == null:
			amount = 0
		var duration = Globals.get_data(effect_info, "duration_turn")
		if duration == null or duration <= 0:
			BehaviorEvents.emit_signal("OnUseEnergy", obj, -amount)
		else:
			obj.set_attrib("converter.extra_ap_energy_cost", -amount)
		add_to_ongoing_effect(obj, effect_info, "energy")
		if is_player:
			if amount < 0:
				BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]The anomaly is syphoning energy from the ship ![/color]")
			else:
				BehaviorEvents.emit_signal("OnLogLine", "[color=lime]The anomaly was full of free energy, we're gaining energy ![/color]")
				
	effect_info = anomaly.get_attrib("anomaly.scanner")
	if effect_info != null:
		var amount : int = Globals.get_data(effect_info, "range_bonus")
		obj.set_attrib("scanner_result.range_bonus", amount)
		add_to_ongoing_effect(obj, effect_info, "scanner")
		if is_player:
			if amount < 0:
				BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]A magnetic pulse from the Anomaly has disabled our scanners ![/color]")
			else:
				BehaviorEvents.emit_signal("OnLogLine", "[color=lime]The anomaly resonate with our scanners giving them a boost ![/color]")
		


func add_to_ongoing_effect(obj, effect_info, type):
	var duration = Globals.get_data(effect_info, "duration_turn")
	if duration == null or duration <= 0:
		return
		
	var effect_data = str2var(var2str(effect_info))
	effect_data["type"] = type
	effect_data["last_turn_update"] = Globals.total_turn
	var obj_effect_list = obj.get_attrib("anomaly.effects")
	if obj_effect_list == null:
		obj_effect_list = []
	obj_effect_list.push_back(effect_data)
	obj.set_attrib("anomaly.effects", obj_effect_list)
	
	
func update_effect(obj, effect_list):
	var to_clear = []
	for effect in effect_list:
		if "duration_turn" in effect:
			effect.duration_turn -= Globals.total_turn - effect.last_turn_update
			effect.last_turn_update = Globals.total_turn
		
		if not "duration_turn" in effect or effect.duration_turn <= 0:
			to_clear.push_back(effect)
			remove_effect(obj, effect)
				
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
		converter_data.erase("extra_ap_energy_cost")
		obj.set_attrib("converter", converter_data)
		if obj.get_attrib("type") == "player":
			BehaviorEvents.emit_signal("OnLogLine", "[color=lime]The energy Syphon has subsided[/color]")
	if effect.type == "scanner":
		var scanner_data = obj.get_attrib("scanner_result")
		scanner_data.erase("range_bonus")
		obj.set_attrib("scanner_result", scanner_data)
		if obj.get_attrib("type") == "player":
			BehaviorEvents.emit_signal("OnLogLine", "[color=lime]Scanners are back to normal[/color]")
			
	BehaviorEvents.emit_signal("OnAnomalyEffectGone", obj, effect)

