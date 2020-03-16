extends Node

func _ready():
	BehaviorEvents.connect("OnLevelReady", self, "OnLevelReady_Callback")
	BehaviorEvents.connect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	
	
func OnPlayerCreated_Callback(player):
	# Init
	var data : Dictionary = player.get_attrib("runes.%s" % self.name, {})
	if data.empty():
		data["title"] = "Chief Science Officer"
		data["full_name"] = "Leonard Grayson"
		player.set_attrib("runes.%s" % self.name, data)
	BehaviorEvents.disconnect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	
func OnLevelReady_Callback():
	var first_depth : int = 3
	var last_depth : int = 7
	var first_depth_chance : float = 0.1
	var last_depth_chance : float = 1.0
	var current_depth : int = Globals.LevelLoaderRef.current_depth
	
	var current_chance : float = 0.0
	if current_depth >= first_depth and current_depth <= last_depth:
		current_chance = range_lerp(current_depth, first_depth, last_depth, first_depth_chance, last_depth_chance)
		
	if MersenneTwister.rand_float() <= current_chance:
		TriggerBeginning()

func TriggerBeginning():
	var player : Attributes = Globals.get_first_player()
	player.set_attrib("runes.%s.step" % self.name, "begin")
	player.set_attrib("consumable", {"hull_regen":[{"data":"data/json/items/special/radiation_damage.json"}]})
	
