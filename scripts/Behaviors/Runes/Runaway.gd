extends Node

var _can_prompt := true

func _ready():
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	BehaviorEvents.connect("OnLevelReady", self, "OnLevelReady_Callback")
	BehaviorEvents.connect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	
func OnWaitForAnimation_Callback():
	_can_prompt = false
	
func OnAnimationDone_Callback():
	_can_prompt = true
	
func OnPlayerCreated_Callback(player):
	# Init
	var data : Dictionary = player.get_attrib("runes.%s" % self.name, {})
	if data.empty():
		data["title"] = "CMO"
		data["name"] = "Eric 'doc' Brown"
		data["status"] = "Active"
		data["log"] = "No Recommendation"
		data["color"] = [0.1,0.1,0.1]
		player.set_attrib("runes.%s" % self.name, data)
	BehaviorEvents.disconnect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	
func OnLevelReady_Callback():
	for wormhole in Globals.LevelLoaderRef.objByType["wormhole"]:
		if "human_branch" in wormhole.get_attrib("src"):
			TriggerBeginning()
	
	var current_level_data = Globals.LevelLoaderRef.GetCurrentLevelData()
	if Globals.get_data(current_level_data, "runaway_hideout", false) == true:
		TriggerEnd()

func TriggerEnd():
	#TODO: Should have some animation/cutscene?
	var has_converter := false
	var player : Attributes = Globals.get_first_player()
	if player.get_attrib("runes.%s.completed" % self.name, false) == true:
		return
		
	var converter = player.get_attrib("mounts.converter")[0]
	var converter_data = null
	if converter != null and converter != "":
		converter_data = Globals.LevelLoaderRef.LoadJSON(converter)
	if converter_data != null and Globals.get_data(converter_data, "end_game") == true:
		has_converter = true
	else:
		var in_cargo = false
		var cargo = player.get_attrib("cargo.content")
		for item in cargo:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			if item.count > 0 and Globals.get_data(data, "end_game") == true:
				in_cargo = true
				break
		if in_cargo == true:
			has_converter = true
	
	if has_converter == true:
		if _can_prompt == false:
			yield(BehaviorEvents, "OnAnimationDone")
		BehaviorEvents.emit_signal("OnWaitForAnimation")
		BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "As you enter the system a small ship opens a communication channel, Eric's face shows up on screen : \"I'll be damned, is this what I think it is ? By god man, you've done it! I'm sorry I ever doubted you, please, let me come back aboard and let's go home, I'm so tired of this place! Can you believe these barabarians still use scalpels?\"", "title":"CMO Eric 'doc' Brown", "callback_object":self, "callback_method":"Outro_Done_Callback"})
	else:
		BehaviorEvents.emit_signal("OnLogLine", "You detect Eric's bio-signal but he refuses to open a channel with you...")

func Outro_Done_Callback():
	var player : Attributes = Globals.get_first_player()
	BehaviorEvents.emit_signal("OnLogLine", "[color=lime]Eric 'doc' Brown has rejoined the ship's crew![/color]")
	#data["status"] = "Active"
	#data["log"] = "No Recommendation
	player.set_attrib("runes.%s.status" % self.name, "Redacted")
	player.set_attrib("runes.%s.log" % self.name, "Record expunged, everyone can go home")
	player.set_attrib("runes.%s.color" % self.name, [0.0,0.4,0.0])
	player.set_attrib("runes.%s.completed" % self.name, true)
	BehaviorEvents.emit_signal("OnAnimationDone")

func TriggerBeginning():
	var player : Attributes = Globals.get_first_player()
	var data : Dictionary = player.get_attrib("runes.%s" % self.name, {})
	if "intro_done" in data and data["intro_done"] == true:
		return
	
	if _can_prompt == false:
		yield(BehaviorEvents, "OnAnimationDone")
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "As you enter the system, your Chief Medical Officer approach you :\"You know Cap'n, I don't like this wild goose chase of yours. Imma go find myself some accepting human colony. If you do find your crazy artifact you come'n get me ya hear ?\"", "title":"CMO Eric 'doc' Brown"})
	yield(BehaviorEvents, "OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "You try to reason him, try to make him stay, but before you know it, he boards one of the shuttles and head for the nearest human outpost...", "title":"CMO Eric 'doc' Brown", "callback_object":self, "callback_method":"Intro_Done_Callback"})
	
func Intro_Done_Callback():
	var player : Attributes = Globals.get_first_player()
	player.set_attrib("runes.%s.status" % self.name, "MIA")
	player.set_attrib("runes.%s.log" % self.name, "Deserter. Ran to the human colonies in Homeworld 3")
	player.set_attrib("runes.%s.color" % self.name, [0.58,0.58,0.0])
	player.set_attrib("runes.%s.intro_done" % self.name, true)
	BehaviorEvents.emit_signal("OnAnimationDone")
