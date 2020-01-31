extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var frame_id := 1
var cur_time := 0.0
export(float) var frame_rate := 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	cur_time += delta
	if cur_time >= frame_rate:
		cur_time -= frame_rate
		move_to_next_frame()
#	pass

func move_to_next_frame():
	frame_id += 1
	frame_id = (frame_id % self.get_child_count()) + 1
	var visible_frame := "tombstone%02d" % frame_id
	for child in self.get_children():
		if child.name == visible_frame:
			child.visible = true
		else:
			child.visible = false
