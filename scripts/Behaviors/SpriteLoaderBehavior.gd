extends Node

export(NodePath) var levelLoaderNode
#export(NodePath) var TileNode

#var tileNodeRef
var levelLoaderRef

func _ready():
	levelLoaderRef = get_node(levelLoaderNode)
	#tileNodeRef = get_node(TileNode)
	levelLoaderRef.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")

func OnObjectLoaded_Callback(obj, parent):
	if obj.has("sprite"):
		#TODO: cache load in a dictionary ?
		var scene = load("res://scenes/tileset_source/" + obj["sprite"] + ".tscn")
		var node = scene.instance()
		parent.call_deferred("add_child", node)
		#var tileIndex = tileNodeRef.tile_set.find_tile_by_name ( obj["sprite"] )
		#tileNodeRef.set_cellv( pos, tileIndex, flip_x, flip_y, transpose )
	if obj.has("sprite_choice"):
		# TODO: handle know/unknown (multiple look for potions in nethack, but always the same look in a given game)
		var x = int(randf() * obj["sprite_choice"].size())
		var scene = load("res://scenes/tileset_source/" + obj["sprite_choice"][x] + ".tscn")
		var node = scene.instance()
		parent.call_deferred("add_child", node)
		#var tileIndex = tileNodeRef.tile_set.find_tile_by_name ( obj["sprite_choice"][x] )
		#tileNodeRef.set_cellv( pos, tileIndex, flip_x, flip_y, transpose )
	#if obj.has("sprite_list"):
	#	for t in obj["sprite_list"]:
	#		var final_pos = pos + Vector2(t["offset"][0], t["offset"][1])
	#		var tileIndex = tileNodeRef.tile_set.find_tile_by_name ( t["name"] )
	#		tileNodeRef.set_cellv( final_pos, tileIndex, flip_x, flip_y, transpose )

func CanDrawSprite(sprite_data, pos):
	var current_obj_at_pos = levelLoaderRef.GetTileData(pos)
	if current_obj_at_pos.size() == 0:
		return true
	
	var sprite_level = 0
	if sprite_data.has("z_order"):
		sprite_level = sprite_data["z_order"]
		
	var max_level = -1
	for obj in current_obj_at_pos:
		if obj.has("z_order") && obj["z_order"] > max_level:
			max_level = obj["z_order"]
			
	if sprite_level >= max_level:
		print(sprite_level, " >= ", max_level, " at ", pos)
		return true
	else:
		print(sprite_level, " >= ", max_level, " at ", pos)
		return false
		
	
#s = Sprite.new() # Create a new sprite!
#add_child(s) # Add it as a child of this node.
#s.queue_free() # Queues the Node for deletion at the end of the current Frame.

#var scene = load("res://myscene.tscn") # Will load when the script is instanced.
#var scene = preload("res://myscene.tscn") # Will load when parsing the script.
#var node = scene.instance()
#add_child(node)
		
		
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
