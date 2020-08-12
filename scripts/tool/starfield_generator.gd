extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export(NodePath) var viewport_path = "Viewport"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _input(event):
	if (event is InputEventMouseButton):
		var cur_datetime : Dictionary = OS.get_datetime()
		var save_file_path = "user://screenshot-%s%s%s-%s%s%s.png" % [cur_datetime["year"], cur_datetime["month"], cur_datetime["day"], cur_datetime["hour"], cur_datetime["minute"], cur_datetime["second"]]
		var image = get_node(viewport_path).get_texture().get_data()
		image.flip_y()
		image.save_png(save_file_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
