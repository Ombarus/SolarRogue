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
	
	
	
func Outline_Red_Callback():
	Complete_Step("outline_red")
func Outline_Blue_Callback():
	Complete_Step("outline_blue")
func Outline_White_Callback():
	Complete_Step("outline_white")
	
		
func Complete_Step(step_name):
	var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
	if not step_name in steps:
		steps.push_back(step_name)
		PermSave.set_attrib("tutorial.completed_steps", steps)
	
func ResetTuto_Callback():
	PermSave.set_attrib("tutorial.completed_steps", [])
	StartTuto_Callback()
	
func OnGUIChanged_Callback(current_menu):
	if Active == false:
		return
		
	if current_menu == "ConverterV2":
		var player : Attributes = Globals.get_first_player() 
		var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
		
		if "pre_conv_inv" in steps and not "conv_inv" in steps:
			var cargo = player.get_attrib("cargo.content")
			for item in cargo:
				var data = Globals.LevelLoaderRef.LoadJSON(item.src)
				var type = Globals.get_data(data, "type")
				var name : String = Globals.mytr(Globals.get_data(data, "name_id"))
				if type == "food":
					BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "TUTO refill our energy", "text_fmt":[name, name], "title":"Tutorial: Converter"})
					BehaviorEvents.emit_signal("OnHighlightUIElement", "Swap")
					steps.push_back("conv_inv")
					PermSave.set_attrib("tutorial.completed_steps", steps)
					break
					
	elif current_menu == "InventoryV2":
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
						var tr_slot = Globals.mytr(slot)
						BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "TUTO equip our new", "text_fmt":[tr_slot, tr_slot], "title":"Tutorial: Inventory"})
						BehaviorEvents.emit_signal("OnHighlightUIElement", "Craft")
						steps.push_back("equip_inv")
						PermSave.set_attrib("tutorial.completed_steps", steps)
						break
						
	elif current_menu == "HUD":
		var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
		if not "movement" in steps:
			BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "TUTO order the helm", "title":"Tutorial: Ship Movement", "callback_object":self, "callback_method":"Movement_Done_Callback"})
			
func OnScannerUpdated_Callback(obj):
	if Active == false or obj.get_attrib("type") != "player":
		return
		
	var level_id = Globals.LevelLoaderRef.GetLevelID()
	var new_objs = obj.get_attrib("scanner_result.new_in_range." + level_id, [])
	var new_out_objs = obj.get_attrib("scanner_result.new_out_of_range." + level_id, [])
	var known_anomalies = obj.get_attrib("scanner_result.known_anomalies." + level_id, {})
	
	var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
	var done := false # only one tuto prompt at a time, in order of priority
	
	#TODO: check also currently in scanner range in case we need to trigger multiple tutorials
	if not "outline_red" in steps:
		for id in new_objs:
			var o = Globals.LevelLoaderRef.GetObjectById(id)
			if o != null:
				var outline : Sprite = o.find_node("outline", true, false)
				if outline != null:
					if outline.modulate == Color(1.0, 0.0, 0.0, 1.0):
						BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "TUTO deemed hostile", "title":"Tutorial: Tactical, Hostiles", "callback_object":self, "callback_method":"Outline_Red_Callback"})
						done = true
			
	if done == true:
		return
					
	if not "outline_blue" in steps:
		for id in new_objs:
			var o = Globals.LevelLoaderRef.GetObjectById(id)
			if o != null:
				var outline : Sprite = o.find_node("outline", true, false)
				if outline != null:
					if outline.modulate == Color(0.0, 0.0, 1.0, 1.0) and o.get_attrib("ai.aggressive", false) == false:
						BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "TUTO deemed neutral", "title":"Tutorial: Tactical, Neutral", "callback_object":self, "callback_method":"Outline_Blue_Callback"})
						done = true
	
	if done == true:
		return
		
	if not "outline_white" in steps:
		for id in new_objs:
			var o = Globals.LevelLoaderRef.GetObjectById(id)
			if o != null:
				var outline : Sprite = o.find_node("outline", true, false)
				if outline != null:
					if outline.modulate == Color(1.0, 1.0, 1.0, 1.0):
						BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "TUTO Boardable targets", "title":"Tutorial: Tactical, Boarding", "callback_object":self, "callback_method":"Outline_White_Callback"})
						done = true
	
	if done == true:
		return
		
	if not "planet_scan" in steps:
		for id in new_objs:
			var o = Globals.LevelLoaderRef.GetObjectById(id)
			if o != null and o.get_attrib("type") == "planet" and not "planet_scan" in steps:
				BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "TUTO planet close by", "title":"Tutorial: Harvesting", "callback_object":self, "callback_method":"Planet_Scan_Done_Callback"})
				BehaviorEvents.emit_signal("OnHighlightUIElement", "Weapon")
				done = true
				break
	
	if done == true:
		return
		
	if not "food_scan" in steps:
		for id in new_objs:
			var o = Globals.LevelLoaderRef.GetObjectById(id)
			if o != null and o.get_attrib("type") == "food" and not "food_scan" in steps:
				BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "TUTO base elements", "title":"Tutorial: Energy", "callback_object":self, "callback_method":"Food_Scan_Done_Callback"})
				BehaviorEvents.emit_signal("OnHighlightUIElement", "Grab")
				break

func OnPickup_Callback(picker : Attributes):
	if Active == false or picker.get_attrib("type") != "player":
		return
		
	var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
	
	var cargo = picker.get_attrib("cargo.content")
	var done := false
	
	# do it in separate loop to guaranty the priority
	if not "pre_conv_inv" in steps:
		for item in cargo:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			var type = Globals.get_data(data, "type")
			if type == "food":
				BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "TUTO the [c]onv button", "title":"Tutorial: Converter", "callback_object":self, "callback_method":"Pre_Conv_Inv_Callback"})
				BehaviorEvents.emit_signal("OnHighlightUIElement", "Converter")
				done = true
				break
	
	if not done and not "pre_equip_inv" in steps:
		for item in cargo:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			var slot = Globals.get_data(data, "equipment.slot")
			if slot != null:
				var available_slot : bool = picker.get_attrib("mounts." + slot, []).size() > 0
				if available_slot == true:
					BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "TUTO mount on ship", "title":"Tutorial: Inventory", "callback_object":self, "callback_method":"Pre_Equip_Inv_Callback"})
					BehaviorEvents.emit_signal("OnHighlightUIElement", "Inventory")
					break
	
