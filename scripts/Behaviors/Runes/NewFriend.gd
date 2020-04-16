extends Node

var _can_prompt := true

func _ready():
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	BehaviorEvents.connect("OnLevelReady", self, "OnLevelReady_Callback")
	BehaviorEvents.connect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	BehaviorEvents.connect("OnDamageTaken", self, "OnDamageTaken_Callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_Callback")
	
func OnTransferPlayer_Callback(old_player, new_player):
	new_player.set_attrib("runes.%s" % self.name, old_player.get_attrib("runes.%s" % self.name, {}))
	
func OnWaitForAnimation_Callback():
	_can_prompt = false
	
func OnAnimationDone_Callback():
	_can_prompt = true
	
func OnPlayerCreated_Callback(player):
	# Init
	var data : Dictionary = player.get_attrib("runes.%s" % self.name, {})
	if data.empty():
		data["title"] = "Cook?"
		data["name"] = ""
		data["status"] = "None"
		data["log"] = "We could use a good cook..."
		data["color"] = [0.1,0.1,0.1]
		player.set_attrib("runes.%s" % self.name, data)
	BehaviorEvents.disconnect("OnPlayerCreated", self, "OnPlayerCreated_Callback")
	
func OnLevelReady_Callback():
	var player : Attributes = Globals.get_first_player()
	var level_id : String = Globals.LevelLoaderRef.GetLevelID()
	var friend_id : int = player.get_attrib("runes.%s.friend_id" % self.name, -1)
	if friend_id != -1:
		return
	var tested_levels : Array = player.get_attrib("runes.%s.tested_levels" % self.name, [])
	if level_id in tested_levels:
		return
		
	var first_depth : int = 6
	#var first_depth : int = 1
	var last_depth : int = 10
	var current_depth : int = Globals.LevelLoaderRef.current_depth
	
	# no point in testing anything if chance is 0 anyway
	if current_depth < first_depth or current_depth > last_depth:
		return
	
	var first_depth_chance : float = 0.05
	var last_depth_chance : float = 1.0
	
	var current_chance : float = 0.0
	
	current_chance = range_lerp(current_depth, first_depth, last_depth, first_depth_chance, last_depth_chance)
		
	tested_levels.push_back(level_id)
	player.set_attrib("runes.%s.tested_levels" % self.name, tested_levels)
	
	print("new friend : current_depth : %d, current_chance : %.3f" % [current_depth, current_chance])
	if MersenneTwister.rand_float() <= current_chance:
		TriggerBeginning(player)

func OnDamageTaken_Callback(target, shooter, damage_type):
	var destroyed = target.get_attrib("destroyable.destroyed", false)
	var is_friend = target.get_attrib("newfriend", false)
	if not destroyed or not is_friend:
		return
		
	TriggerEnd(target)
	# 1. As the ship explode, a small escape pod launches from the ship and opens a communication channel
	# 2. Xileen : Don't shoot! Wait, I'm sorry, I didn't know who you were. Look, I'll pay you back, let me live on board and I'll do anything you want! Even the dishes! Come on, you won't regret it, I know everything about this sector!
	# 3. Spawn boardable probe
	# 4. You accept his surrender and Xileen joins your crew!
	# 5. Update crew roster (Xileen, VIP, Cook)
	# 6. Reveal whole map ? (intel...)

func TriggerEnd(friend : Attributes):
	var spawn_coord : Vector2 = Globals.LevelLoaderRef.World_to_Tile(friend.position)
	var escape_pod : Attributes = Globals.LevelLoaderRef.RequestObject("data/json/ships/human/player_probe.json", spawn_coord, null)
	
	if _can_prompt == false:
		yield(BehaviorEvents, "OnAnimationDone")
		
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "As the ship explode, a small escape pod launches from the ship and opens a communication channel", "title":"Xileen"})
	yield(BehaviorEvents, "OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "Xileen : \"Don't shoot! Wait, I'm sorry, I didn't know who you are. Look, I'll pay you back, let me live on board and I'll do anything you want! Even the dishes! Come on, you won't regret it, I know everything about this sector!\"", "title":"Xileen"})
	yield(BehaviorEvents, "OnPopGUI")
	BehaviorEvents.emit_signal("OnPushGUI", "StoryPrompt", {"text": "You accept his surrender and Xileen joins your crew!", "title":"Xileen"})
	yield(BehaviorEvents, "OnPopGUI")
	Outro_Done_Callback()
	

func Outro_Done_Callback():
	var player : Attributes = Globals.get_first_player()
	BehaviorEvents.emit_signal("OnLogLine", "[color=lime]Xileen has joined the ship's crew![/color]")
	player.set_attrib("runes.%s.status" % self.name, "VIP")
	player.set_attrib("runes.%s.title" % self.name, "Cook")
	player.set_attrib("runes.%s.name" % self.name, "Xileen")
	player.set_attrib("runes.%s.log" % self.name, "His cooking is certainly interesting...")
	player.set_attrib("runes.%s.color" % self.name, [0.0,0.4,0.0])
	player.set_attrib("runes.%s.completed" % self.name, true)
	BehaviorEvents.emit_signal("OnAnimationDone")

func TriggerBeginning(player : Attributes):
	var data : Dictionary = player.get_attrib("runes.%s" % self.name, {})
	if "intro_done" in data and data["intro_done"] == true:
		return
	
	var spawn_coord = Globals.LevelLoaderRef.GetRandomEmptyTile()
	var friend = Globals.LevelLoaderRef.RequestObject("data/json/ships/special/xileen.json", spawn_coord, null)
	friend.set_attrib("newfriend", true)
	player.set_attrib("runes.%s.friend_id" % self.name, friend.get_attrib("unique_id"))
