extends ViewportContainer


onready var _viewport = get_node("Viewport")


# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("resized", self, "on_size_changed")


func on_size_changed():
	var new_size = self.rect_size
	#print("Viewport Resized : " + str(new_size))
	_viewport.size = new_size
