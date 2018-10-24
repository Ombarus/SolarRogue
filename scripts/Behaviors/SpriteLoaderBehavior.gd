extends Node

export(NodePath) var levelLoaderRef
export(NodePath) var TileNode

var tileNodeRef

func _ready():
	get_node(levelLoaderRef).connect("OnObjectLoaded", self, "OnObjectLoaded_Callback")
	tileNodeRef = get_node(TileNode)
	pass

func OnObjectLoaded_Callback(obj, pos):
	var flip_x = false
	var flip_y = false
	var transpose = false
	if obj.has("sprite"):
		var tileIndex = tileNodeRef.tile_set.find_tile_by_name ( obj["sprite"] )
		tileNodeRef.set_cellv( pos, tileIndex, flip_x, flip_y, transpose )
	if obj.has("sprite_choice"):
		# TODO: handle know/unknown (multiple look for potions in nethack, but always the same look in a given game)
		var x = int(randf() * obj["sprite_choice"].size())
		var tileIndex = tileNodeRef.tile_set.find_tile_by_name ( obj["sprite_choice"][x] )
		tileNodeRef.set_cellv( pos, tileIndex, flip_x, flip_y, transpose )
	if obj.has("sprite_list"):
		for t in obj["sprite_list"]:
			var tileIndex = tileNodeRef.tile_set.find_tile_by_name ( t["name"] )
			var final_pos = pos + Vector2(t["offset"][0], t["offset"][1])
			tileNodeRef.set_cellv( final_pos, tileIndex, flip_x, flip_y, transpose )

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
