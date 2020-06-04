extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.w
	# Initialization here
	BehaviorEvents.connect("OnPlayerDeath", self, "OnPlayerDeath_Callback")
	
func OnPlayerDeath_Callback():
	var player = Globals.LevelLoaderRef.objByType["player"][0]
	var cur_level = Globals.LevelLoaderRef.current_depth
	var player_name = player.get_attrib("player_name")
	var message_v2 := ""
	var message_success := ""
	var game_won = player.get_attrib("game_won")
	var result = null
	if game_won != null and game_won == true:
		message_success += Globals.mytr("SUCCESS_CONGRATS")
		message_v2 += "[center]%s \n%s:\n" % [Globals.mytr("The crew of the"), player_name]
		message_v2 += _crew_message(player)
		result = PermSave.END_GAME_STATE.won
	elif player.get_attrib("destroyable.current_hull", 1) <= 0:
		var killer_name = Globals.mytr(player.get_attrib("destroyable.damage_source"))
		message_v2 += Globals.mytr("Killed by %s", [killer_name])
		result = PermSave.END_GAME_STATE.destroyed
	elif player.get_attrib("converter.stored_energy") <= 0:
		message_v2 += Globals.mytr("Stranded")
		result = PermSave.END_GAME_STATE.entropy
	else:
		message_v2 += Globals.mytr("self destructed")
		result = PermSave.END_GAME_STATE.suicide
	if game_won == null or game_won == false:
		message_v2 += "\n" + Globals.mytr("on the %dth wormhole", [cur_level+1])
	message_v2 += "\n" + Globals.mytr("EPITAPH_VISITED", [Globals.LevelLoaderRef.num_generated_level])
	var lowest_diff = player.get_attrib("lowest_diff")
	lowest_diff += 1
	message_v2 += "\n\n" + Globals.mytr("Difficulty: %d", [lowest_diff])
		
	var score = CalculateScore(player, game_won)
	update_leaderboard(player, score, result)
	message_v2 += "\n\n%s\n%d" % [Globals.mytr("EPITAPH_SCORE"), score]
	if game_won != null and game_won == true:
		message_v2 += "[/center]"
	var death_screen_data = {
		"player_name": player_name,
		"epitaph": message_v2,
		"message_success": message_success,
		"is_success": game_won != null and game_won == true,
		"callback_object":self,
		"callback_method":"ScoreDone_Callback"
	}
	BehaviorEvents.emit_signal("OnPushGUI", "DeathScreen", death_screen_data)

func CalculateScore(player, game_won):
	var final_score = 0
	
	var stored_energy = player.get_attrib("converter.stored_energy")
	if stored_energy != null:
		final_score += round(stored_energy)
	
	var holding_converter = 0
	var converter = player.get_attrib("mounts.converter")[0]
	var converter_data = null
	# if you don't have a converter mounted
	if converter != null and converter != "":
		converter_data = Globals.LevelLoaderRef.LoadJSON(converter)
	if converter_data != null and Globals.get_data(converter_data, "end_game") == true:
		holding_converter += 100000
	else:
		var in_cargo = false
		var cargo = player.get_attrib("cargo.content")
		for item in cargo:
			var data = Globals.LevelLoaderRef.LoadJSON(item.src)
			if item.count > 0 and Globals.get_data(data, "end_game") == true:
				in_cargo = true
				break
		if in_cargo == true:
			holding_converter += 50000
			
	# Add number of floor explored * 1 000
	
	# Add x / turns
	if game_won != null and game_won == true:
		var turn_score = 1000000.0 / (Globals.total_turn+1)
		final_score += round(turn_score)
		
	var num_generated_level = Globals.LevelLoaderRef.num_generated_level
	final_score += 1000 * num_generated_level
	
	var runes = player.get_attrib("runes", {})
	for rune in runes:
		var completed = player.get_attrib("runes.%s.completed" % rune, false)
		if completed == true:
			final_score += 2500
	
	var difficulty_boost = player.get_attrib("lowest_diff") + 1 #0 to 4, make it 1 to 5 as multiplier
	
	return final_score * difficulty_boost
	
func update_leaderboard(player, final_score, result):
	#{"player_name":"Ombarus the greatest", "final_score":100000, "status":END_GAME_STATE.won, "generated_levels":20, "died_on":-1},
	var data = {}
	data["player_name"] = player.get_attrib("player_name")
	data["final_score"] = final_score
	data["status"] = result
	data["generated_levels"] = Globals.LevelLoaderRef.num_generated_level
	data["died_on"] = Globals.LevelLoaderRef.current_depth
	
	var leaderboard = PermSave.get_attrib("leaderboard")
	for i in range(leaderboard.size()):
		if leaderboard[i].final_score <= final_score:
			leaderboard.insert(i, data)
			data = null
			break
	
	if data != null:
		leaderboard.push_back(data)
	
	if leaderboard.size() > 100:
		leaderboard.pop_back()
		
	# will save on disk even tough the leaderboard was passed by ref and it already up to date
	PermSave.set_attrib("leaderboard", leaderboard)

func ScoreDone_Callback():
	get_tree().change_scene("res://scenes/MainMenu.tscn")

func _crew_message(player : Attributes) -> String:
	var final_text = ""
	var victory_crew := []
	var failed_crew := []
	
	var runes = player.get_attrib("runes", {})
	for rune in runes:
		var completed = player.get_attrib("runes.%s.completed" % rune, null)
		var name : String = player.get_attrib("runes.%s.name" % rune, "")
		if name.empty():
			# weirdo? shouldn't happen, if name is empty title MUST be something...
			name = "a %s" % player.get_attrib("runes.%s.title" % rune, "weirdo?")
		if completed == null: # urgh.... maybe this should be a enum state ?
			victory_crew.push_back(name)
		elif completed == true:
			victory_crew.push_back("[color=lime]%s[/color]" % name)
		else:
			failed_crew.push_back(name)
	
	final_text += PoolStringArray(victory_crew).join(", ")
	final_text += "\n\n"
	if failed_crew.size() > 0:
		final_text += Globals.mytr("Sadly left behind:")
		final_text += "\n[color=red]%s[/color]" % [PoolStringArray(failed_crew).join(", ")]
	else:
		final_text += Globals.mytr("Did not leave anyone behind!")
	final_text += "\n"
	
	return final_text
