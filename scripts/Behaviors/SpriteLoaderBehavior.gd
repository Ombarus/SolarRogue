extends Node

export(NodePath) var levelLoaderNode
export(Material) var ghost_material
#export(NodePath) var TileNode

#var tileNodeRef
var levelLoaderRef

func _ready():
	levelLoaderRef = get_node(levelLoaderNode)
	#tileNodeRef = get_node(TileNode)
	BehaviorEvents.connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")

func OnObjectLoaded_Callback(obj):
	var attrib = obj.base_attributes
	var node = null
	if attrib.has("sprite"):
		#TODO: cache load in a dictionary ?
		var scene = load("res://scenes/tileset_source/" + attrib["sprite"] + ".tscn")
		node = scene.instance()
	if attrib.has("sprite_choice"):
		# TODO: handle know/unknown (multiple look for potions in nethack, but always the same look in a given game)
		var x = int(randf() * attrib["sprite_choice"].size())
		var scene = load("res://scenes/tileset_source/" + attrib["sprite_choice"][x] + ".tscn")
		node = scene.instance()
		
	obj.call_deferred("add_child", node)
	if obj.get_attrib("ghost_memory") != null:
		node.material = ghost_material

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
