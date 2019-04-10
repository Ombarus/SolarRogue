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
	var message = ""
	var game_won = player.get_attrib("game_won")
	var result = null
	if game_won != null and game_won == true:
		message += "The Converter of Yendor uses the energy of the wormhole itself to rip a hole trough space. \nYou spool up the engines and glide through it. On the other side HOME is waiting ! \n\nYou made it !"
		result = PermSave.END_GAME_STATE.won
	elif player.get_attrib("destroyable.hull") <= 0:
		message += "The %s has been destroyed" % player_name
		result = PermSave.END_GAME_STATE.destroyed
	elif player.get_attrib("converter.stored_energy") <= 0:
		message += "The %s has run out of energy, and you will spend an eternity drifting through empty void" % player_name
		result = PermSave.END_GAME_STATE.entropy
	else:
		message += "The %s self destructed, everyone on board was lost" % player_name
		result = PermSave.END_GAME_STATE.suicide
	if game_won == null or game_won == false:
		message += "\nYou died on the %dth wormhole" % (cur_level+1)
	message += "\nYou visited %d solar systems" % Globals.LevelLoaderRef.num_generated_level
		
	var score = CalculateScore(player, game_won)
	update_leaderboard(player, score, result)
	message += "\nYour final score is : " + str(score)
	BehaviorEvents.emit_signal("OnPushGUI", "DeathScreen", {"text":message, "callback_object":self, "callback_method":"ScoreDone_Callback"})

func CalculateScore(player, game_won):
	var final_score = 0
	
	var stored_energy = player.get_attrib("converter.stored_energy")
	if stored_energy != null:
		final_score += round(stored_energy)
	
	var holding_converter = 0
	var converter = player.get_attrib("mounts.converter")[0]
	var converter_data = Globals.LevelLoaderRef.LoadJSON(converter)
	if Globals.get_data(converter_data, "end_game") == true:
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
		var turn_score = 1000000.0 / Globals.total_turn
		final_score += round(turn_score)
		
	var num_generated_level = Globals.LevelLoaderRef.num_generated_level
	final_score += 1000 * num_generated_level
	
	return final_score
	
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
	
	# will save on disk even tough the leaderboard was passed by ref and it already up to date
	PermSave.set_attrib("leaderboard", leaderboard)

func ScoreDone_Callback():
	get_tree().change_scene("res://scenes/MainMenu.tscn")
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
