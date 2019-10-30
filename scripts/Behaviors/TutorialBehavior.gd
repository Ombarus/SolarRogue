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
	
func StartTuto_Callback():
	Active = PermSave.get_attrib("tutorial.enabled")
		
func Movement_Done_Callback():
	Complete_Step("movement")
	
func Planet_Scan_Done_Callback():
	Complete_Step("planet_scan")
		
func Food_Scan_Done_Callback():
	Complete_Step("food_scan")
		
func Complete_Step(step_name):
	var steps : Array = PermSave.get_attrib("tutorial.completed_steps")
	if not step_name in steps:
		steps.push_back(step_name)
		PermSave.set_attrib("tutorial.completed_steps", steps)
	
func ResetTuto_Callback():
	PermSave.set_attrib("tutorial.completed_steps", [])
	StartTuto_Callback()
	
func OnGUIChanged_Callback(current_menu):
	if current_menu == "HUD":
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
			BehaviorEvents.emit_signal("OnPushGUI", "TutoPrompt", {"text": "Captain, the ship's scanners have detected a planet closeby. We should get close to it and fire our weapons, we could get useful materials from the debris.", "title":"Tutorial: Harvesting", "callback_object":self, "callback_method":"Planet_Scan_Done_Callback"})
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