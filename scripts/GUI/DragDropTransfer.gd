extends Button

var MyData = {}

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func get_drag_data(position):
	set_drag_preview(self.duplicate())
	return MyData
	
func can_drop_data(position, data):
	if not "origin" in MyData:
		return false
		
	return MyData.origin.choice_can_drop_data(self, data)
	
func drop_data(position, data):
	MyData.origin.choice_drop_data(self, data)