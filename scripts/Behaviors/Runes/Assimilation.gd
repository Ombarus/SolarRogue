extends Node

var _can_prompt := true

func _ready():
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	BehaviorEvents.connect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	BehaviorEvents.connect("OnPlayerTurn", self, "OnPlayerTurn_Callback")
	BehaviorEvents.connect("OnDamageTaken", self, "OnDamageTaken_Callback")
	
func OnTransferPlayer_Callback(old_player, new_player):
	new_player.set_attrib("runes.%s" % self.name, old_player.get_attrib("runes.%s" % self.name, {}))
	
func OnWaitForAnimation_Callback():
	#print("runaway : wait for anim")
	_can_prompt = false
	
func OnAnimationDone_Callback():
	#print("runaway : waiting over")
	_can_prompt = true
	
func OnPlayerCreated_Callback(player):
	# Init
	var data : Dictionary = player.get_attrib("runes.%s" % self.name, {})
	if data.empty():
		data["title"] = "CSO"
		data["name"] = "Major Bren Derlin"
		data["status"] = "Active"
		data["log"] = "Very Reclusive"
		data["color"] = [0.1,0.1,0.1]
		player.set_attrib("runes.%s" % self.name, data)
	BehaviorEvents.disconnect("OnPlayerCreated", self, "OnPlayerCreated_Callback")

func OnPlayerTurn_Callback(obj):
	var cooldown := 1000.0
	var event_range := 1500.0
#	var cooldown := 5.0
#	var event_range := 15.0
	
	var generated_levels : int = Globals.LevelLoaderRef.num_generated_level
	
	# don't break anything in the early game to avoid attrition
	if generated_levels <= 3:
		return
	
	var next_event : float = obj.get_attrib("runes.%s.next_event" % self.name, 0.0)
	if next_event <= 0.0:
		# shedule first event
		next_event = MersenneTwister.rand(event_range) + Globals.total_turn
		obj.set_attrib("runes.%s.next_event" % self.name, next_event)
		
	if next_event <= Globals.total_turn:
		_break_something(obj)
		
		next_event = MersenneTwister.rand(event_range) + Globals.total_turn + cooldown
		obj.set_attrib("runes.%s.next_event" % self.name, next_event)
		
	
func _break_something(obj):
	# find all brokable items
	var potentials := []
	var mounts = obj.get_attrib("mounts")
	for key in mounts:
		var items = mounts[key]
		var attributes = obj.get_attrib("mount_attributes." + key)
		for i in range(items.size()):
			if items[i].empty() or "broken.json" in attributes[i].get("selected_variation", ""):
				continue
			var potential_data = Globals.LevelLoaderRef.LoadJSON(items[i])
			var variations = potential_data.get("variations", [])
			for variation in variations:
				if "broken.json" in variation["src"]:
					potentials.push_back({"key":key, "idx":i, "item_id":items[i], "modified_attributes":attributes[i], "item_data":potential_data})
					break
			
	var cargo = obj.get_attrib("cargo.content")
	for i in range(cargo.size()):
		var item = cargo[i]
		if "broken.json" in Globals.get_data(item, "modified_attributes.selected_variation", ""):
			continue
		var potential_data = Globals.LevelLoaderRef.LoadJSON(item.src)
		var variations = potential_data.get("variations", [])
		for variation in variations:
			if "broken.json" in variation["src"]:
				potentials.push_back({"item_id":item.src, "idx":i, "modified_attributes":item.get("modified_attributes", {}), "item_data":potential_data})
				
	if potentials.size() <= 0:
		return
	
	var break_idx = MersenneTwister.rand(potentials.size())
	var broken_row = potentials[break_idx]
	var broken_display_name := ""
	if "key" in broken_row:
		# update mount
		var item_attributes = obj.get_attrib("mount_attributes." + broken_row["key"])
		var item_mounts = obj.get_attrib("mounts." + broken_row["key"])
		var previous_variation = item_attributes[broken_row["idx"]].get("selected_variation", "")
		
		var item_data = Globals.LevelLoaderRef.LoadJSON(item_mounts[broken_row["idx"]])
		broken_display_name = Globals.EffectRef.get_display_name(item_data, item_attributes[broken_row["idx"]])
		
		var new_data = str2var(var2str(item_attributes[broken_row["idx"]]))
		if not previous_variation.empty():
			new_data["previous_variation"] = previous_variation
		new_data["selected_variation"] = "data/json/items/effects/broken.json"
		BehaviorEvents.emit_signal("OnUpdateMountAttribute", obj, broken_row["key"], broken_row["idx"], new_data)
	else:
		# update inventory
		var inventory_row = cargo[broken_row["idx"]]
		var modified_attributes = inventory_row.get("modified_attributes", {})
		var previous_variation = modified_attributes.get("selected_variation", "")
		
		var item_data = Globals.LevelLoaderRef.LoadJSON(broken_row.item_id)
		broken_display_name = Globals.EffectRef.get_display_name(item_data, modified_attributes)
		
		var new_data = str2var(var2str(modified_attributes))
		if not previous_variation.empty():
			new_data["previous_variation"] = previous_variation
		Globals.set_data(new_data, "selected_variation", "data/json/items/effects/broken.json")
		BehaviorEvents.emit_signal("OnUpdateInvAttribute", obj, broken_row.item_id, modified_attributes, new_data)
	
	#TODO: more meaningfull message and put some variations (piece of crap!, ...)
	var choices = {
		"[color=red]Our %s Just Broke![/color]":100,
		"[color=red]Something's wrong with our %s[/color]":100,
		"[color=red]%s just went out of alignment[/color]":70,
		"[color=red]Engineering report a broken %s[/color]":50,
		"[color=red]There seems to be a problem with %s[/color]":50,
		"[color=red]%s just exceeded it's designed operating conditions![/color]":25,
		"[color=red]Something just happened to %s[/color]":25,
		"[color=red]What the hell happened to %s?![/color]":10,
		"[color=red]%s is a real piece of crap![/color]":5,
		"[color=red]Bloody Hell, what's wrong with %s?![/color]":1
	}

	BehaviorEvents.emit_signal("OnLogLine", choices, [broken_display_name])
	
	
	
func OnDamageTaken_Callback(target, shooter, damage_type):
	var destroyed = target.get_attrib("destroyable.destroyed", false)
	var is_mothership = target.get_attrib("sprite", "") == "vorg_mothership"
	if not destroyed or not is_mothership:
		return
		
	TriggerSuccess()

	
func TriggerSuccess():
	var player : Attributes = Globals.get_first_player()
	
	if _can_prompt == false:
		yield(BehaviorEvents, "OnAnimationDone")
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "RUNE_ASSIMILATION_SUCCESS", "title":"CSO Major Bren Derlin"})
	yield(BehaviorEvents, "OnPopGUI")
	
	BehaviorEvents.emit_signal("OnLogLine", "[color=lime]Vorg Implants have been removed from Major Bren Derlin![/color]")
	player.set_attrib("runes.%s.status" % self.name, "Liberated")
	player.set_attrib("runes.%s.log" % self.name, "Former Vorg Drone")
	player.set_attrib("runes.%s.color" % self.name, [0.0,0.4,0.0])
	player.set_attrib("runes.%s.completed" % self.name, true)
	BehaviorEvents.emit_signal("OnAnimationDone")

