extends Node

signal StartTuto
signal ResetTuto

var Active := false

func _ready():
	Globals.TutorialRef = self
	connect("StartTuto", self, "StartTuto_Callback")
	connect("ResetTuto", self, "ResetTuto_Callback")
	BehaviorEvents.connect("OnGUIChanged", self, "OnGUIChanged_Callback")
	BehaviorEvents.connect("OnScannerUpdated", self, "OnScannerUpdated_Callback")
	BehaviorEvents.connect("OnPositionUpdated", self, "OnPositionUpdated_Callback")
	BehaviorEvents.connect("OnObjectPicked", self, "OnPickup_Callback")
	
func StartTuto_Callback():
	Active = PermSave.get_attrib("tutorial.enabled")
		
func Movement_Done_Callback():
	Complete_Step("movement")
	
func Planet_Scan_Done_Callback():
	Complete_Step("planet_scan")
		
func Food_Scan_Done_Callback():
	Complete_Step("food_scan")
	
func Pre_Equip_Inv_Callback():
	Complete_Step("pre_equip_inv")
	
func Pre_Conv_Inv_Callback():
	Complete_Step("pre_conv_inv")
		
func Complete_Step(step_name):
	var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
	if not step_name in steps:
		steps.push_back(step_name)
		PermSave.set_attrib("tutorial.completed_steps", steps)
	
func ResetTuto_Callback():
	PermSave.set_attrib("tutorial.completed_steps", [])
	StartTuto_Callback()
	
func OnGUIChanged_Callback(current_menu):
	if current_menu == "ConverterV2":
		var player : Attributes = Globals.get_first_player() 
		var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
		
		if "pre_conv_inv" in steps and not "conv_inv" in steps:
			var cargo = player.get_attrib("cargo.content")
			for item in cargo:
				var data = Globals.LevelLoaderRef.LoadJSON(item.src)
				var type = Globals.get_data(data, "type")
				var name : String = Globals.get_data(data, "name_id")
				if type == "food":
					BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "Captain, Let refill our energy by converting this " +  name + "\n1. Select 'Recycle Energy' from the list on the left\n2. Select the '" + name + "' on the right\n3. Click the 'Craft' Button", "title":"Tutorial: Converter"})
					BehaviorEvents.emit_signal("OnHighlightUIElement", "Swap")
					steps.push_back("conv_inv")
					PermSave.set_attrib("tutorial.completed_steps", steps)
					break
					
	if current_menu == "InventoryV2":
		var player : Attributes = Globals.get_first_player() 
		var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
		
		if "pre_equip_inv" in steps and not "equip_inv" in steps:
			var cargo = player.get_attrib("cargo.content")
			for item in cargo:
				var data = Globals.LevelLoaderRef.LoadJSON(item.src)
				var slot = Globals.get_data(data, "equipment.slot")
				if slot != null:
					var available_slot : bool = player.get_attrib("mounts." + slot, []).size() > 0
					if available_slot == true:
						BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "Captain, To equip our new " + slot + " just select it in the cargo list on the right and select the 'mount' button to install or replace the currently equiped " + slot, "title":"Tutorial: Inventory"})
						BehaviorEvents.emit_signal("OnHighlightUIElement", "Craft")
						steps.push_back("equip_inv")
						PermSave.set_attrib("tutorial.completed_steps", steps)
						break
	elif current_menu == "HUD":
		var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
		if not "movement" in steps:
			BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "Captain, order the helm to move by using the numpad keys, cliking or taping the screen", "title":"Tutorial: Ship Movement", "callback_object":self, "callback_method":"Movement_Done_Callback"})
			
func OnScannerUpdated_Callback(obj):
	if obj.get_attrib("type") != "player":
		return
		
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var new_objs = obj.get_attrib("scanner_result.new_in_range." + level_id)
	var new_out_objs = obj.get_attrib("scanner_result.new_out_of_range." + level_id)
	var unkown_objs = obj.get_attrib("scanner_result.unknown." + level_id)
	var known_anomalies = obj.get_attrib("scanner_result.known_anomalies." + level_id, {})
	
	var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
	
	for id in new_objs:
		var o = Globals.LevelLoaderRef.GetObjectById(id)
		if o != null and o.get_attrib("type") == "planet" and not "planet_scan" in steps:
			BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "Captain, the ship's scanners have detected a planet close by. We should get close within firing range and shoot a few missiles, we could get useful materials from the debris.", "title":"Tutorial: Harvesting", "callback_object":self, "callback_method":"Planet_Scan_Done_Callback"})
			BehaviorEvents.emit_signal("OnHighlightUIElement", "Weapon")
			
		elif o != null and o.get_attrib("type") == "food" and not "food_scan" in steps:
			BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "Captain, the ship's scanners have detected base elements that could be used to power the ship. Get on top of it and use the tractor beam to bring it into our cargo holds.", "title":"Tutorial: Energy", "callback_object":self, "callback_method":"Food_Scan_Done_Callback"})
			BehaviorEvents.emit_signal("OnHighlightUIElement", "Grab")
			
			
func OnPositionUpdated_Callback(obj):
	if obj.get_attrib("type") != "player":
		return
		
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var cur_objs = obj.get_attrib("scanner_result.cur_in_range." + level_id)
	var new_objs = obj.get_attrib("scanner_result.new_in_range." + level_id)
	
	#var best_move = _targetting.ClosestFiringSolution(obj_tile, player_tile, data)


func OnPickup_Callback(picker : Attributes):
	if picker.get_attrib("type") != "player":
		return
		
	var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
	
	var cargo = picker.get_attrib("cargo.content")
	
	# do it in separate loop to guaranty the priority
	if not "conv_inv" in steps:
		for item in cargo:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			var type = Globals.get_data(data, "type")
			if type == "food":
				BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "Captain, we've picked up an item that could be used to refuel the ship. click on the [c]onv button to warm up our energy-to-matter converter", "title":"Tutorial: Converter", "callback_object":self, "callback_method":"Pre_Conv_Inv_Callback"})
				BehaviorEvents.emit_signal("OnHighlightUIElement", "Converter")
				#if not "pre_conv_inv" in steps:
				#	steps.push_back("pre_equip_inv")
				#	PermSave.set_attrib("tutorial.completed_steps", steps)
				#	break
	
	if not "equip_inv" in steps:
		for item in cargo:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			var slot = Globals.get_data(data, "equipment.slot")
			if slot != null:
				var available_slot : bool = picker.get_attrib("mounts." + slot, []).size() > 0
				if available_slot == true:
					BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "Captain, we've picked up an item that could be mounted on our ship. Please head to the inventory screen for more info.", "title":"Tutorial: Inventory", "callback_object":self, "callback_method":"Pre_Equip_Inv_Callback"})
					BehaviorEvents.emit_signal("OnHighlightUIElement", "Inventory")
					#if not "pre_equip_inv" in steps:
					#	steps.push_back("pre_equip_inv")
					#	PermSave.set_attrib("tutorial.completed_steps", steps)
					#	return
	