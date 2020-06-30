extends Node2D

export(int) var stream_tile_radius = 5

func _ready():
	#BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	OnLevelLoaded_Callback()
	
	
func OnLevelLoaded_Callback():
	if Globals.LevelLoaderRef != null:
		var player_node = Globals.LevelLoaderRef.objByType["player"][0]
		self.position = player_node.position # set origin around player
	
	var cur_x = 0
	var cur_y = 0
	var dx = 0
	var dy = -1
	var star_child = load("res://scenes/BG_Child.tscn")
	
	for i in range(stream_tile_radius * stream_tile_radius):
		var pos = Vector2((cur_x*256), (cur_y*256))
		var tile
		if Globals.LevelLoaderRef == null:
			tile = Vector2(cur_x / 2.0, cur_y / 2.0)
		else:
			tile = Globals.LevelLoaderRef.World_to_Tile(to_global(pos))

		var n = star_child.instance()
		n.random_seed = int(tile.x) & ~int(tile.y)
		n.Refresh()
		yield(get_tree(), "idle_frame")
		#print("add_child (", i, "/", stream_tile_radius * stream_tile_radius, ") :", n)
		self.add_child(n)
		n.position = pos
		if cur_x == cur_y or (cur_x < 0 and cur_x == -cur_y) or (cur_x > 0 and cur_x == 1-cur_y):
			var tmp = dx
			dx = -dy
			dy = tmp
		cur_x = cur_x + dx
		cur_y = cur_y + dy
