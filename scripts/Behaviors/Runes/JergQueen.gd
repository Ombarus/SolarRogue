extends Node

var _can_prompt := true

func _ready():
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	BehaviorEvents.connect("OnLevelReady", self, "OnLevelReady_Callback")
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
		data["title"] = "XO"
		data["name"] = "Kane Nostro"
		data["status"] = "Active"
		data["log"] = "Loves Micromanaging"
		data["color"] = [0.1,0.1,0.1]
		player.set_attrib("runes.%s" % self.name, data)
	BehaviorEvents.disconnect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	
	
func OnLevelReady_Callback():
	var current_level_data = Globals.LevelLoaderRef.GetCurrentLevelData()
	if "jerg_branch" in current_level_data.src:
		TriggerBeginning()

func OnPlayerTurn_Callback(obj):	
	var deadline : float = obj.get_attrib("runes.%s.deadline" % self.name, 0)
	var failed = obj.get_attrib("runes.%s.completed" % self.name, null)
	if deadline <= 0 or failed != null:
		return
	
	if Globals.total_turn >= deadline:
		TriggerFail(obj)
		return
		
	var lifetime : float = obj.get_attrib("runes.%s.lifetime" % self.name, 0)
	var remaining = deadline - Globals.total_turn
	var per_life = remaining / lifetime # new = 100%, nearly dead = 0%
	
	if per_life < 0.25 and obj.get_attrib("runes.%s.warn3" % self.name, false) == false:
		BehaviorEvents.emit_signal("OnLogLine", "[color=red]Kane is feverish and seem to be talking with something![/color]")
		obj.set_attrib("runes.%s.warn3" % self.name, true)
	elif per_life < 0.50 and obj.get_attrib("runes.%s.warn2" % self.name, false) == false:
		BehaviorEvents.emit_signal("OnLogLine", "[color=red]Kane's condition is getting worse![/color]")
		obj.set_attrib("runes.%s.warn2" % self.name, true)
	elif per_life < 0.75 and obj.get_attrib("runes.%s.warn1" % self.name, false) == false:
		BehaviorEvents.emit_signal("OnLogLine", "[color=red]Kane is complaining of severe headache![/color]")
		obj.set_attrib("runes.%s.warn1" % self.name, true)
	
	
func OnDamageTaken_Callback(target, shooter, damage_type):
	var destroyed = target.get_attrib("destroyable.destroyed", false)
	var is_queen = target.get_attrib("sprite", "") == "jerg_queen"
	if not destroyed or not is_queen:
		return
		
	TriggerSuccess()
	
func TriggerFail(player):	
	if _can_prompt == false:
		yield(BehaviorEvents, "OnAnimationDone")
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "The XO broke free of his restraints and started destroying everything on the ship while yelling in some kind of alien language. We had no choice but to kill him before he could do any more damage.", "title":"XO Kane Nostro"})
	yield(BehaviorEvents, "OnPopGUI")
	
	BehaviorEvents.emit_signal("OnLogLine", "[color=red]XO Kane Nostrum died from the Jerg Plague![/color]")
	
	var max_hull = player.get_attrib("destroyable.hull")
	var cur_hull = player.get_attrib("destroyable.current_hull", max_hull)
	var new_hull = max(1, cur_hull - 0.1 * max_hull)
	player.set_attrib("destroyable.current_hull", new_hull)\
	# Radiation damage type is mostly to play sfx and vfx. For now I think I can use the same.
	#TODO: different animation for sabotage
	BehaviorEvents.emit_signal("OnDamageTaken", player, null, Globals.DAMAGE_TYPE.radiation)
	player.set_attrib("runes.%s.status" % self.name, "Victim")
	player.set_attrib("runes.%s.log" % self.name, "Died from the Jerg Plague")
	player.set_attrib("runes.%s.color" % self.name, [0.4,0.0,0.0])
	player.set_attrib("runes.%s.completed" % self.name, false)
	BehaviorEvents.emit_signal("OnAnimationDone")
	
	
func TriggerSuccess():
	var player : Attributes = Globals.get_first_player()
	var failed = player.get_attrib("runes.%s.completed" % self.name, null)
	if failed == false:
		BehaviorEvents.emit_signal("OnLogLine", "In the wreckage of the mothership you find a cure for the floating spores but it's too late...")
		return
		
	if _can_prompt == false:
		yield(BehaviorEvents, "OnAnimationDone")
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "Inside the wreckage of the mothership you find a cure for the spore infecting XO Kane. After a few days in the medbay he makes a full recovery!", "title":"XO Kane Nostro"})
	yield(BehaviorEvents, "OnPopGUI")
	
	BehaviorEvents.emit_signal("OnLogLine", "[color=lime]XO Kane Nostrum was saved from the Jerg Plague![/color]")
	player.set_attrib("runes.%s.status" % self.name, "Immunized")
	player.set_attrib("runes.%s.log" % self.name, "No sequels from the Jerg Plague")
	player.set_attrib("runes.%s.color" % self.name, [0.0,0.4,0.0])
	player.set_attrib("runes.%s.completed" % self.name, true)
	BehaviorEvents.emit_signal("OnAnimationDone")
	
	
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
	#player.set_attrib("runes.%s.completed" % self.name, false)
	var deadline : int = MersenneTwister.rand(3500 - 1500) + 1500
	player.set_attrib("runes.%s.deadline" % self.name, Globals.total_turn + deadline)
	player.set_attrib("runes.%s.lifetime" % self.name, deadline)
	BehaviorEvents.emit_signal("OnAnimationDone")
