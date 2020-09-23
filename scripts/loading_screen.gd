extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var vp_size = self.get_viewport().size
	if get_viewport().is_size_override_enabled():
		vp_size = get_viewport().get_size_override()
	self.position = vp_size / 2.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
