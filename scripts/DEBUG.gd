extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	var l = Globals.LevelLoaderRef
	var r = get_node("/root/Root/GameTiles")
	var scene = load("res://scenes/Debug.tscn")
	for x in range(l.levelSize.x):
		for y in range(l.levelSize.y):
			var world_pos = l.Tile_to_World(Vector2(x,y))
			var n = scene.instance()
			n.position = world_pos
			n.text = str(l.World_to_Tile(world_pos).x) + ", " + str(l.World_to_Tile(world_pos).y)
			r.call_deferred("add_child", n)


#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
