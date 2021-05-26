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

func OnLogLine_Callback(msg, fmt=[]):
	_cur_chance = base_chance
	_cur_cooldown = Globals.total_turn + 10.0
	_log_last_turn = true
	
func OnPlayerTurn_Callback(obj):
	
	var log_choices = {
		"[color=teal]Reminder, Crew meeting today at 6:00[/color]":75,
		"[color=teal]A new baby girl was born today![/color]":50,
		"[color=teal]A new baby boy was born today![/color]":50,
		"[color=teal]The engineers have finished refiting the deuterium relay couplers[/color]":50,
		"[color=teal]Captain to the bridge[/color]":75,
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
		BehaviorEvents.emit_signal("OnLogLine", log_choices)
		_cur_cooldown = Globals.total_turn + cooldown
	else:
		_cur_chance += chance_increment
