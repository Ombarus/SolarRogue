extends Node

var damage_json = "data/json/items/special/radiation_damage.json"

var _can_prompt := true

func _ready():
	BehaviorEvents.connect("OnLevelReady", self, "OnLevelReady_Callback")
	BehaviorEvents.connect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	BehaviorEvents.connect("OnDamageTaken", self, "OnDamageTaken_Callback")
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	
func OnWaitForAnimation_Callback():
	_can_prompt = false
	
func OnAnimationDone_Callback():
	_can_prompt = true
	
func OnDamageTaken_Callback(target, shooter, damage_type):
	var player : Attributes = Globals.get_first_player()
	if target == player and target.get_attrib("runes.%s.completed" % self.name, null) == null:
		var cur_hull : float = target.get_attrib("destroyable.current_hull")
		var max_hull : float = target.get_attrib("destroyable.hull")
		var hull_percent : float = cur_hull / max_hull
		if hull_percent < 0.1:
			TriggerFailure(player)
	if target.get_attrib("radiation_emitter", false) == true and player.get_attrib("runes.%s.completed" % self.name, null) == null:
		TriggerSuccess(player)
				
	
func OnPlayerCreated_Callback(player):
	# Init
	var data : Dictionary = player.get_attrib("runes.%s" % self.name, {})
	if data.empty():
		data["title"] = "Chief Science Officer"
		data["full_name"] = "Leonard Grayson"
		player.set_attrib("runes.%s" % self.name, data)
	BehaviorEvents.disconnect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	
func OnLevelReady_Callback():
	var player : Attributes = Globals.get_first_player()
	var level_id : String = Globals.LevelLoaderRef.GetLevelID()
	if player.get_attrib("runes.%s.radiation_level" % self.name, "") == level_id:
		_add_radiation(player)
		BehaviorEvents.emit_signal("OnLogLine", "[color=yellow]Intense Radiations are Damaging the Hull![/color]")
	else:
		_remove_radiation(player, false)
	if player.get_attrib("runes.%s.step" % self.name, "") != "":
		return
		
	var tested_levels : Array = player.get_attrib("runes.%s.tested_levels" % self.name, [])
	if level_id in tested_levels:
		return
		
	var first_depth : int = 3
	var last_depth : int = 7
	var current_depth : int = Globals.LevelLoaderRef.current_depth
	
	# no point in testing anything if chance is 0 anyway
	if current_depth < first_depth or current_depth > last_depth:
		return
	
	var first_depth_chance : float = 0.1
	var last_depth_chance : float = 1.0
	
	var current_chance : float = 0.0
	
	current_chance = range_lerp(current_depth, first_depth, last_depth, first_depth_chance, last_depth_chance)
		
	tested_levels.push_back(level_id)
	player.set_attrib("runes.%s.tested_levels" % self.name, tested_levels)
	
	print("current_depth : %d, current_chance : %.3f" % [current_depth, current_chance])
	if MersenneTwister.rand_float() <= current_chance:
		TriggerBeginning(player)

func TriggerBeginning(player : Attributes):
	player.set_attrib("runes.%s.step" % self.name, "intro")
	_add_radiation(player)
	var level_id : String = Globals.LevelLoaderRef.GetLevelID()
	player.set_attrib("runes.%s.radiation_level" % self.name, level_id)
	var spawn_coord = Globals.LevelLoaderRef.GetRandomEmptyTile()
	var planet = Globals.LevelLoaderRef.RequestObject("data/json/stellar/planet_radiation.json", spawn_coord, null)
	#planet.z_index = 998
	
	if _can_prompt == false:
		yield(BehaviorEvents, "OnAnimationDone")
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "As you enter the system heavy waves of radiation start tearing appart the hull. Your chief science officer Grayson explains.", "title":"CSO Leonard Grayson"})
	yield(BehaviorEvents, "OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "Grayson: \"Captain, these radiations are specifically designed to penetrate our shields. They must emanate from a nearby planet as a defense system left over by an ancient race. I will try to remodulate our shield to protect us. In the mean time, I suggest you find and destroy whatever is creating the radiation matrix.\"", "title":"CSO Leonard Grayson", "callback_object":self, "callback_method":"Intro_Done_Callback"})
	
func Intro_Done_Callback():
	var player : Attributes = Globals.get_first_player()
	player.set_attrib("runes.%s.step" % self.name, "intro_done")
	BehaviorEvents.emit_signal("OnAnimationDone")
	
func TriggerSuccess(player : Attributes):
	_remove_radiation(player)
	if _can_prompt == false:
		yield(BehaviorEvents, "OnAnimationDone")
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "With a satisfying explosion, the radiation generator is destroyed taking with it, half the planet.", "title":"CSO Leonard Grayson"})
	yield(BehaviorEvents, "OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "Grayson: \"Good job captain.\"", "title":"CSO Leonard Grayson", "callback_object":self, "callback_method":"Outro_Done_Callback"})

func Outro_Done_Callback():
	var player : Attributes = Globals.get_first_player()
	BehaviorEvents.emit_signal("OnLogLine", "[color=lime]Leonard Grayson didn't have to make a difficult decision![/color]")
	player.set_attrib("runes.%s.completed" % self.name, true)
	BehaviorEvents.emit_signal("OnAnimationDone")

func TriggerFailure(player : Attributes):
	_remove_radiation(player)
	if _can_prompt == false:
		yield(BehaviorEvents, "OnAnimationDone")
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "Grayson: \"Captain, I believe I have found a way to tune the ship's harmonics to the radiation field. However someone must do it from inside the generator which is exposed to the radiations.\"", "title":"CSO Leonard Grayson"})
	yield(BehaviorEvents, "OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "You:\"Leonard, No...\"\n\nGrayson: \"Do not grieve captain, the needs of the many outweight the needs of the few... or the one.\"", "title":"CSO Leonard Grayson", "callback_object":self, "callback_method":"Fail_Done_Callback"})
	
func Fail_Done_Callback():
	var player : Attributes = Globals.get_first_player()
	player.set_attrib("runes.%s.completed" % self.name, false)	
	BehaviorEvents.emit_signal("OnLogLine", "[color=red]Leonard Grayson sacrificed his life to save the ship...[/color]")
	
	var max_hull : float = player.get_attrib("destroyable.hull")
	player.set_attrib("destroyable.current_hull", max_hull)
	BehaviorEvents.emit_signal("OnAnimationDone")
	BehaviorEvents.emit_signal("OnDamageTaken", player, null, Globals.DAMAGE_TYPE.healing)

func _remove_radiation(player : Attributes, is_completed=true):
	var regens = player.get_attrib("consumable.hull_regen", [])
	var index := 0
	for index in range(regens.size()):
		if regens[index].data == damage_json:
			break
			
	regens.remove(index)
	player.set_attrib("consumable.hull_regen", regens)
	if is_completed == true:
		player.set_attrib("runes.%s.radiation_level" % self.name, "")

func _add_radiation(player : Attributes):
	var regens = player.get_attrib("consumable.hull_regen", [])
	# In case we're loading the player and he already has the effect
	for regen in regens:
		if regen.data == damage_json:
			return
			
	regens.push_back({"data":damage_json})
	player.set_attrib("consumable.hull_regen", regens)
