extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	var leaders = PermSave.get_attrib("leaderboard")
	get_node("leaderlist").Content = leaders
	
	#var scrollbar = get_node("leaderlist").get_v_scrollbar()
	#scrollbar.allow_lesser = true
	#scrollbar.allow_greater = true

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
