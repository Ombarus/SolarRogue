extends Control

var frame_id := 1
var cur_time := 0.0
export(float) var frame_rate := 0.1

func _ready():
	visible = false # make sure to avoid perf hit

func _process(delta):
	# on PC this is the most expensive update!
	if visible == false:
		return
	cur_time += delta
	if cur_time >= frame_rate:
		cur_time -= frame_rate
		move_to_next_frame()

func move_to_next_frame():
	frame_id += 1
	frame_id = (frame_id % self.get_child_count()) + 1
	var visible_frame := "tombstone%02d" % frame_id
	for child in self.get_children():
		if child.name == visible_frame:
			child.visible = true
		else:
			child.visible = false
