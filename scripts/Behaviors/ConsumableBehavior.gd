extends Node

func _ready():
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	BehaviorEvents.connect("OnValidateConsumption", self, "OnValidateConsumption_Callback")
	
func OnObjectLoaded_Callback(obj):
	var random_charge_range = obj.get_attrib("consumable.random_charge", [])
	var charge = obj.get_attrib("consumable.charge", null)
	if random_charge_range.size() != 2 or charge != null:
		return
	
	charge = MersenneTwister.rand(random_charge_range[1] - random_charge_range[0]) + random_charge_range[0]
	obj.set_attrib("consumable.charge", charge)
	
func OnValidateConsumption_Callback(obj, data, key, attrib):
	var is_player = obj.get_attrib("type") == "player"
	var energy_used = Globals.get_data(data, "consumable.energy")
	var ap_used = Globals.get_data(data, "consumable.ap")
	if ap_used != null and ap_used > 0:
		BehaviorEvents.emit_signal("OnUseAP", obj, ap_used)
	if energy_used != null and energy_used > 0:
		BehaviorEvents.emit_signal("OnUseEnergy", obj, energy_used)
		
	var charge = Globals.get_data(attrib, "consumable.charge", null)
	if charge == null:
		charge = Globals.get_data(data, "consumable.charge", null)
		
	var rand_chance = Globals.get_data(data, "consumable.random_charge", [])
	if rand_chance.size() == 2 and charge == null:
		charge = MersenneTwister.rand(rand_chance[1] - rand_chance[0]) + rand_chance[0]
		if is_player:
			BehaviorEvents.emit_signal("OnLogLine", "Your %s uses one of it's charge", [Globals.EffectRef.get_display_name(data, attrib)])
		charge -= 1
		var new_data = {}
		if attrib != null:
			new_data = str2var(var2str(attrib))
		Globals.set_data(new_data, "consumable.charge", charge)
		BehaviorEvents.emit_signal("OnUpdateInvAttribute", obj, key, attrib, new_data)
	elif charge != null and charge > 1:
		if is_player:
			BehaviorEvents.emit_signal("OnLogLine", "Your %s uses one of it's charge", [Globals.EffectRef.get_display_name(data, attrib)])
		charge -= 1
		var new_data = str2var(var2str(attrib))
		Globals.set_data(new_data, "consumable.charge", charge)
		BehaviorEvents.emit_signal("OnUpdateInvAttribute", obj, key, attrib, new_data)
	elif charge != null:
		charge -= 1
		
	if charge == null or charge < 1:
		if is_player:
			BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]Your %s used it's last charge[/color]", [Globals.EffectRef.get_display_name(data, attrib)])
		BehaviorEvents.emit_signal("OnRemoveItem", obj, key, attrib)
