extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

export var base_attributes = {} # can be kept by reference, no need to serialize
export var modified_attributes = {} # locally modified attribute (like current position). Should be saved !


func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
