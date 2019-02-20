extends ItemList

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	self.add_item("bleh1")
	self.add_item("bleh2")
	self.add_item("bleh3")
	self.add_item("bleh4")
	self.add_item("bleh5", load("res://icon.png"))
	set_item_icon_region

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
