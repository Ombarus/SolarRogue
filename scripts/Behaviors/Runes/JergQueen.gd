extends Node

var _can_prompt := true

func _ready():
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	BehaviorEvents.connect("OnLevelReady", self, "OnLevelReady_Callback")
	BehaviorEvents.connect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
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
		data["title"] = "XO"
		data["name"] = "Kane Nostro"
		data["status"] = "Active"
		data["log"] = "No Recommendation"
		data["color"] = [0.1,0.1,0.1]
		player.set_attrib("runes.%s" % self.name, data)
	BehaviorEvents.disconnect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	
func OnLevelReady_Callback():
	var current_level_data = Globals.LevelLoaderRef.GetCurrentLevelData()
	if "jerg_branch" in current_level_data.src:
		TriggerBeginning()

func OnObjTurn_Callback(obj):
	var is_player : bool = obj.get_attrib("type") == "player"
	if not is_player:
		return
	
	var deadline : float = obj.get_attrib("runes.%s.deadline" % self.name, 0)
	if deadline <= 0.0:
		return
		
	# update deadline
	var last_turn_update = obj.get_attrib("runes.%s.last_update" % self.name)
	var elapsed = Globals.total_turn - last_turn_update
	deadline -= elapsed
	
	obj.set_attrib("runes.%s.deadline" % self.name, deadline)
	obj.set_attrib("runes.%s.last_update" % self.name, Globals.total_turn)
	
	if deadline <= 0.0:
		TriggerFail(obj)
	
func OnDamageTaken_Callback(target, shooter, damage_type):
	var destroyed = target.get_attrib("destroyable.destroyed", false)
	var is_queen = target.get_attrib("sprite", "")
	if not destroyed or not is_queen:
		return
		
	TriggerSuccess(target)
	
func TriggerFail(player):
	pass
	
func TriggerSuccess(queen):
	pass
	
	
#func TriggerEnd():
#	#TODO: Should have some animation/cutscene?
#	var has_converter := false
#	var player : Attributes = Globals.get_first_player()
#	if player.get_attrib("runes.%s.completed" % self.name, false) == true:
#		return
#
#	var converter = player.get_attrib("mounts.converter")[0]
#	var converter_data = null
#	if converter != null and converter != "":
#		converter_data = Globals.LevelLoaderRef.LoadJSON(converter)
#	if converter_data != null and Globals.get_data(converter_data, "end_game") == true:
#		has_converter = true
#	else:
#		var in_cargo = false
#		var cargo = player.get_attrib("cargo.content")
#		for item in cargo:
#			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
#			if item.count > 0 and Globals.get_data(data, "end_game") == true:
#				in_cargo = true
#				break
#		if in_cargo == true:
#			has_converter = true
#
#	if has_converter == true:
#		if _can_prompt == false:
#			yield(BehaviorEvents, "OnAnimationDone")
#		BehaviorEvents.emit_signal("OnWaitForAnimation")
#		BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "RUNE_RUNAWAY_SUCCESS", "title":"CMO Eric 'doc' Brown"})
#		yield(BehaviorEvents, "OnPopGUI")
#		Outro_Done_Callback()
#	else:
#		BehaviorEvents.emit_signal("OnLogLine", "You detect Eric's bio-signal but he refuses to open a channel with you...")

#func Outro_Done_Callback():
#	var player : Attributes = Globals.get_first_player()
#	BehaviorEvents.emit_signal("OnLogLine", "[color=lime]Eric 'doc' Brown has rejoined the ship's crew![/color]")
#	#data["status"] = "Active"
#	#data["log"] = "No Recommendation
#	player.set_attrib("runes.%s.status" % self.name, "Redacted")
#	player.set_attrib("runes.%s.log" % self.name, "Record expunged")
#	player.set_attrib("runes.%s.color" % self.name, [0.0,0.4,0.0])
#	player.set_attrib("runes.%s.completed" % self.name, true)
#	BehaviorEvents.emit_signal("OnAnimationDone")

func TriggerBeginning():
	var player : Attributes = Globals.get_first_player()
	var intro_done : bool = player.get_attrib("runes.%s.intro_done" % self.name, false)
	if intro_done == true:
		return
	
	if _can_prompt == false:
		yield(BehaviorEvents, "OnAnimationDone")
		
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "This region of space is covered in strange spores. The XO has been infected and is hearing voices...", "title":"XO Kane Nostro"})
	yield(BehaviorEvents, "OnPopGUI")
	Intro_Done_Callback()
	
func Intro_Done_Callback():
	var player : Attributes = Globals.get_first_player()
	player.set_attrib("runes.%s.status" % self.name, "Infected")
	player.set_attrib("runes.%s.log" % self.name, "The Jerg Homeworld must have a cure. His situation is getting worse")
	player.set_attrib("runes.%s.color" % self.name, [0.58,0.58,0.0])
	player.set_attrib("runes.%s.intro_done" % self.name, true)
	# Set Completed to false so it's considered "failed" if we don't go back for him
	player.set_attrib("runes.%s.completed" % self.name, false)
	var deadline : int = MersenneTwister.rand(5000 - 3000) + 3000
	player.set_attrib("runes.%s.deadline" % self.name, Globals.total_turn + deadline)
	player.set_attrib("runes.%s.last_update" % self.name, Globals.total_turn)
	BehaviorEvents.emit_signal("OnAnimationDone")
