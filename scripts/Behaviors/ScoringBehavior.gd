extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	BehaviorEvents.connect("OnPlayerDeath", self, "OnPlayerDeath_Callback")
	
func OnPlayerDeath_Callback():
	var player = Globals.LevelLoaderRef.objByType["player"][0]
	var cur_level = Globals.LevelLoaderRef.current_depth
	var message = ""
	if player.get_attrib("destroyable.hull") <= 0:
		message += "You have been destroyed"
	else:
		message += "You have run out of energy, and you will spend an eternity drifting through empty void"
	message += "\nYou died on the %dth wormhole" % cur_level
	message += "\nYour final score is : 0"
	BehaviorEvents.emit_signal("OnPushGUI", "DeathScreen", {"text":message, "callback_object":self, "callback_method":"ScoreDone_Callback"})


func ScoreDone_Callback():
	get_tree().change_scene("res://scenes/MainMenu.tscn")
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
