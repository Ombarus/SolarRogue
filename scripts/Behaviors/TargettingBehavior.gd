extends Node



func _ready():
	BehaviorEvents.connect("OnRequestPlayerTargetting", self,  "OnRequestPlayerTargetting_Callback")
	BehaviorEvents.connect("OnClearOverlay", self, "OnClearOverlay_Callback")
	
func OnClearOverlay_Callback():
	var overlay_nodes = get_tree().get_nodes_in_group("overlay")
	for n in overlay_nodes:
		n.get_parent().remove_child(n)
		n.queue_free()
	
	
func OnRequestPlayerTargetting_Callback(player, weapon):
	var scene = load("res://scenes/tileset_source/targetting_reticle.tscn")
	var player_tile = Globals.LevelLoaderRef.World_to_Tile(player.position)
	var r = get_node("/root/Root/OverlayTiles")
	var n = null
	#for x in range(Globals.LevelLoaderRef.levelSize[0]):
	#	for y in range(Globals.LevelLoaderRef.levelSize[1]):
	#		var dist = player_tile - Vector2(x, y)
	#		if dist.length() >= 2.6:
	#			continue
	#		n = scene.instance()
	#		r.call_deferred("add_child", n)
	#		n.position = Globals.LevelLoaderRef.Tile_to_World(Vector2(x,y))
			
	var fire_radius = weapon.weapon_data.fire_range
	var offset = Vector2(0,0)
	var obj_tile = player_tile
	var bounds = Globals.LevelLoaderRef.levelSize
	
	while round(offset.length()) <= (fire_radius+1):
		while round(offset.length()) <= (fire_radius+1):
			#expanding in positive x & y then checking the other 3 quadrant
			#           |
			#        d  |  a
			#--------------------------
			#        c  |  b
			#           |
			#           |
			var tile = obj_tile + offset
			if round((tile - obj_tile).length()) > fire_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
				pass
			else:
				n = scene.instance()
				r.call_deferred("add_child", n)
				n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
				n.add_to_group("overlay")
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if round((tile - obj_tile).length()) > fire_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
					pass
				else:
					n = scene.instance()
					r.call_deferred("add_child", n)
					n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
					n.add_to_group("overlay")
			if offset.y != 0:
				offset.y *= -1
				tile = obj_tile + offset
				if round((tile - obj_tile).length()) > fire_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
					pass
				else:
					n = scene.instance()
					r.call_deferred("add_child", n)
					n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
					n.add_to_group("overlay")
			if offset.x != 0:
				offset.x *= -1
				tile = obj_tile + offset
				if round((tile - obj_tile).length()) > fire_radius or tile.x < 0 or tile.x > bounds.x or tile.y < 0 or tile.y > bounds.y:
					pass
				else:
					n = scene.instance()
					r.call_deferred("add_child", n)
					n.position = Globals.LevelLoaderRef.Tile_to_World(tile)
					n.add_to_group("overlay")
			offset.y *= -1
			offset.y += 1
		offset.y = 0
		offset.x += 1

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
