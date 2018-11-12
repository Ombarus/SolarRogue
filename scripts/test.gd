extends Node2D

export(String) var text = "" setget set_text

func set_text(newval):
	text = newval
	if has_node("Label"):
		get_node("Label").text = text

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass


#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
