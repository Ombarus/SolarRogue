extends "res://scripts/BG_Control.gd"

export(int) var stream_tile_radius = 10

func _ready():
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	
	
func OnLevelLoaded_Callback():
	var cur_x = 0
	var cur_y = 0
	var dx = 0
	var dy = -1
	
	for i in range(stream_tile_radius * stream_tile_radius):
		var pos = Vector2((cur_x*256) + 128, (cur_y*256) + 128)
		if (pos.x > 0 and pos.x < start_offset.x) and (pos.y > 0 and pos.y < start_offset.y):
			pass
		else:
			var n = get_node("Multi").duplicate()
			n.star_seed = int(randf() * 10000)
			n.position = pos
			n._refresh()
			print("add_child (", i, "/", gen_num * gen_num, ") :", n)
			self.add_child(n)
		if cur_x == cur_y or (cur_x < 0 and cur_x == -cur_y) or (cur_x > 0 and cur_x == 1-cur_y):
			var tmp = dx
			dx = -dy
			dy = tmp
		cur_x = cur_x + dx
		cur_y = cur_y + dy
		_index += 1
