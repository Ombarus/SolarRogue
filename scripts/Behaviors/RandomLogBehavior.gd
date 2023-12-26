extends Node

export(int) var cooldown := 100
export(float) var base_chance := 0.001
export(float) var chance_increment := 0.005

var _cur_chance : float = base_chance
var _log_last_turn := false
var _cur_cooldown = cooldown

func _ready():
	BehaviorEvents.connect("OnLogLine", self, "OnLogLine_Callback")
	BehaviorEvents.connect("OnPlayerTurn", self, "OnPlayerTurn_Callback")
	BehaviorEvents.connect("OnPickObject", self, "OnPickObject_Callback")

func OnLogLine_Callback(msg, fmt=[]):
	_cur_chance = base_chance
	_cur_cooldown = max(_cur_cooldown, Globals.total_turn + 10.0)
	_log_last_turn = true
	
func OnPlayerTurn_Callback(obj):
	
	var log_choices = {
		"[color=teal]Reminder, Crew meeting today at 6:00[/color]":75,
		"[color=teal]Captain to the bridge[/color]":75,
		"[color=teal]A new baby girl was born today![/color]":50,
		"[color=teal]A new baby boy was born today![/color]":50,
		"[color=teal]The engineers have finished refiting the deuterium relay couplers[/color]":50,
		"[color=teal]We've completed the analysis of the latest planetary samples. Nothing new.[/color]":50,
		"[color=teal]Captain on deck![/color]":50,
		"[color=teal]Data indicate that this sun is still in it's main phase[/color]":50,
		"[color=teal]Analysis show this system to host multiple type M planetary bodies[/color]":50,
		"[color=teal]Ensign Kim finished cleaning up the energy vaccum tubes[/color]":50,
		"[color=teal]Food replicator software updated[/color]":50,
		"[color=teal]Ensign Kim finished cleaning the cell in block D[/color]":50,
		"[color=teal]Ensign Kim finished polishing shuttle bay nine[/color]":50,
		"[color=teal]There's a pretty funny meme going around on Stellarbook[/color]":50,
		"[color=teal]Medical bay reports no new cases of hyperflexion of the upper-abdominal region[/color]":50,
		
		# 10% ?
		"[color=teal]Ensign Kim messed up the cleaning again[/color]":5,
		"[color=teal]The local net has been down for the last 6 hours. Productivity increased 900%[/color]":6,
		"[color=teal]Turboencabulator pentametric fan alignement completed[/color]":5,
		"[color=teal]Tonight's dinner : Blueberry pasta[/color]":5,
		"[color=teal]Flux capacitor still not working[/color]":5,
		"[color=teal]Toilet mishaps in corridor six, calling ensign Kim[/color]":5,
		"[color=teal]A new baby xskdfh was born today![/color]":5,
		
		"[color=teal]Received signal requesting blood and skulls for someone. Better ignore that[/color]":5,
		"[color=teal]Received signal praising the emperors protection. Probably some fanatics. Better ignore that[/color]":5,
		"[color=gray](missing translation)[/color][color=teal]Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn[/color]":5,
		"[color=teal]Received signal from a bowl of petunias : 'Oh no, not again.'[/color]":5,
		"[color=teal]Sensor detected a disabled Illudium Q-36 Explosive Space Modulator[/color]":5,
		"[color=teal]Sensor detected a useless carcass of a blimp. It has an Iron sky-dome[/color]":5,
		"[color=teal]Sensor detected strontium-90. Taste great with cola.[/color]":5,
		"[color=teal]The ship's computer has completed it's speed estimate : 12 parsec[/color]":5,
		"[color=teal]The ship's computer has completed a rough triangulation of our position : Not Kansas[/color]":5,
		"[color=teal](W + L) ubba + ( Dub x2)[/color]":5,
		"[color=teal]Not enough power, we require additional Pylons[/color]":5,
	}
	
	
	if _cur_cooldown > Globals.total_turn:
		_cur_chance = base_chance
		return
		
	if _log_last_turn == true:
		_log_last_turn = false
		return
		
	var target = MersenneTwister.rand_float()
	if target < _cur_chance:
		gather_conditional_hint(obj, log_choices)
		BehaviorEvents.emit_signal("OnLogLine", log_choices)
		_cur_cooldown = Globals.total_turn + cooldown
	else:
		_cur_chance += chance_increment

func gather_conditional_hint(player : Attributes, log_choices : Dictionary) -> Dictionary:
	var default_rarity = 200
	var cargo_contents : Array = player.get_attrib("cargo.content")
	var mount_attrib = player.get_attrib("mount_attributes", {})
	var weapons : Array = player.get_attrib("mounts.weapon")
	var weapons_data = Globals.LevelLoaderRef.LoadJSONArray(weapons)
	if weapons_data == null or weapons_data.size() <= 0:
		log_choices["[color=teal]Status report: Weapon Missing[/color]"] = default_rarity + 500
		weapons_data = []
	
	for data in weapons_data:
		if "ammo" in data["weapon_data"]:
			var ammo_src : String = data["weapon_data"]["ammo"]
			var ammo_name : String = Globals.mytr(Globals.LevelLoaderRef.LoadJSON(ammo_src)["name_id"])
			var remaining_ammo : int = 0
			for cargo in cargo_contents:
				if cargo["src"] == ammo_src:
					remaining_ammo += cargo["count"]
			if remaining_ammo <= 5:
				log_choices[Globals.mytr("[color=teal]Warning: %s reserve dangerously low[/color]", [ammo_name])] = default_rarity + 200
	##################
	var energy_left = player.get_attrib("converter.stored_energy")
	if energy_left < 5000:
		log_choices["[color=teal]Captain, Energy expenditure reports show concerningly low level of stored energy[/color]"] = default_rarity + 300
		log_choices["[color=teal]Captain, We're burning through our energy reserves dangerously quickly[/color]"] = default_rarity + 100
		
	##################
	if not Globals.is_mobile():
		log_choices["[color=teal]Hold down the mouse click to force move to your desired location[/color]"] = default_rarity - 150
		log_choices["[color=teal]Use the Numpad numbers to move around with the keyboard[/color]"] = default_rarity - 150
		log_choices["[color=teal]Use the Numpad 5 to wait one turn[/color]"] = default_rarity - 150
		log_choices["[color=teal]Letters between [] show the corresponding keyboard shortcut[/color]"] = default_rarity - 150
	else:
		log_choices["[color=teal]You can use Pinch to zoom[/color]"] = default_rarity - 150
		log_choices["[color=teal]Hold down your finger 2 seconds to force move to your desired location[/color]"] = default_rarity - 100
	
	##################
	var max_hull = player.get_attrib("destroyable.hull")
	var max_shield = player.get_max_shield()
	var current_depth = Globals.LevelLoaderRef.current_depth
	if current_depth > 2 and (max_hull + max_shield) < 40.0:
		log_choices["[color=teal]Captain, we detect rather large ships signature in this region, our ship might not be equipped to handle such large opponent.[/color]"] = default_rarity
		log_choices["[color=teal]Captain, we must proceed with caution![/color]"] = default_rarity
	if current_depth > 6 and (max_hull + max_shield) < 49:
		log_choices["[color=teal]Captain, we detect rather large ships signature in this region, our ship might not be equipped to handle such large opponent.[/color]"] = default_rarity
		log_choices["[color=teal]Captain, we must proceed with caution![/color]"] = default_rarity
	
	##################
	player.init_cargo()
	var cargo_capacity = player.get_attrib("cargo.capacity")
	var cargo_used = player.get_attrib("cargo.volume_used")
	if cargo_used + 20.0 > cargo_capacity:
		log_choices["[color=teal]Captain, our holds are near capacity[/color]"] = default_rarity - 25
		log_choices["[color=teal]Captain, We're running out of space![/color]"] = default_rarity - 25
		log_choices["[color=teal]Captain, We should install additional Gravitic Compactor to free some cargo space![/color]"] = default_rarity - 25

	##################
	for cargo in cargo_contents:
		var effect = Globals.get_data(cargo, "modified_attributes.selected_variation", "")
		if "broken" in effect:
			log_choices["[color=teal]Captain, Engineering reports mission critical item outside of specification.[/color]"] = default_rarity + 75
			log_choices["[color=teal]Captain, Engineering also wants to keep our broken stuff.[/color]"] = default_rarity + 75
			log_choices["[color=teal]Captain, Engineering might have broken some stuff... again.[/color]"] = default_rarity - 150
			break
			
	for key in mount_attrib:
		var found : bool = false
		for attrib in mount_attrib[key]:
			if not attrib.empty() and "broken" in attrib.get("selected_variation", ""):
				log_choices["[color=teal]Captain, Engineering thinks it's a bad idea to install broken components[/color]"] = default_rarity + 200
				found = true
				break
		if found:
			break
	
	##################
	if player.get_attrib("visiting.been_to_human", false) == false:
		log_choices["[color=teal]Captain, There are rumors of a Neutral Human Coalition somewhere.[/color]"] = default_rarity - 150
	
	##################
	var has_human_branch := false
	var has_jerg_branch := false
	var has_vorg_branch := false
	for wormhole in Globals.LevelLoaderRef.objByType["wormhole"]:
		if "human_branch" in wormhole.get_attrib("src"):
			has_human_branch = true
		elif "vorg_branch" in wormhole.get_attrib("src"):
			has_vorg_branch = true
		elif "jerg_branch" in wormhole.get_attrib("src"):
			has_jerg_branch = true
	if player.get_attrib("visiting.seen_jerg", false) == true:
		log_choices["[color=teal]Analysis show that Jerg have semi-organic ship capable of regeneration[/color]"] = default_rarity - 25
		log_choices["[color=teal]Analysis show that Jerg prefer traveling in swarms[/color]"] = default_rarity - 25
		log_choices["[color=teal]Analysis show that Jerg technology favor utility over firepower[/color]"] = default_rarity - 25
		log_choices["[color=teal]Analysis show that Jerg regeneration interfers with shield harmonics[/color]"] = default_rarity - 100
		if player.get_attrib("visiting.been_to_jerg", false) == false and has_jerg_branch:
			log_choices["[color=teal]The Jerg must have a base of operation somewhere.[/color]"] = default_rarity + 250
	if player.get_attrib("visiting.seen_vorg", false) == true:
		log_choices["[color=teal]Analysis show that the Vorg rely heavily on advance technology to overpower their enemies[/color]"] = default_rarity - 25
		log_choices["[color=teal]Analysis show that the Vorg prefer heavily shielded ships over anything else[/color]"] = default_rarity - 25
		log_choices["[color=teal]Analysis show that Vorg ships tend to be slow but deadly[/color]"] = default_rarity - 25
		if player.get_attrib("visiting.been_to_vorg", false) == false and has_vorg_branch:
			log_choices["[color=teal]The Vorg must have a base of operation somewhere.[/color]"] = default_rarity + 250
			
	##################
	if player.get_attrib("visiting.seen_cristal", false) == false:
		log_choices["[color=teal]There are rumors of crystals that can power battleships for months[/color]"] = 30
	
	return log_choices

func OnPickObject_Callback(picker : Attributes, picked : Attributes):
	if "diluted_cristals" in picked.get_attrib("src"):
		picker.set_attrib("visiting.seen_cristal", true)
		BehaviorEvents.disconnect("OnPickObject", self, "OnPickObject_Callback")
