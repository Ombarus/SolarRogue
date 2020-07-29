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
	var node = null
	if obj.get_attrib("sprite") != null:
		#TODO: cache load in a dictioary ?
		var sprite_name : String = obj.get_attrib("sprite")
		var cur_depth : int = Globals.LevelLoaderRef.current_depth
		var worm_depth : int = obj.get_attrib("depth", 0)
		if obj.get_attrib("type") == "wormhole" and worm_depth <= cur_depth:
			sprite_name = sprite_name + "_up"
		#if attrib.type == "wormhole":
		#	sprite_name = "wormhole_old"
		var scene = load("res://scenes/tileset_source/" + sprite_name + ".tscn")
		node = scene.instance()
	elif obj.get_attrib("sprite_choice") != null:
		var sprite_choice : Array = obj.get_attrib("sprite_choice")
		# TODO: handle know/unknown (multiple look for potions in nethack, but always the same look in a given game)
		var x = MersenneTwister.rand(sprite_choice.size())
		# Save the sprite we chose in modified_attrib so we don't randomize again when loading the level
		# and also when duplicating the object for ghost memories
		obj.set_attrib("sprite", sprite_choice[x])
		if obj.get_attrib("icon") != null:
			obj.set_attrib("icon", obj.get_attrib("icon")[x])
		var scene = load("res://scenes/tileset_source/" + sprite_choice[x] + ".tscn")
		node = scene.instance()
	
	self.call_deferred("add_child_and_set_material", obj, node)
	#obj.call_deferred("add_child", node)

func add_child_and_set_material(obj, child):
	obj.add_child(child)
	if obj.get_attrib("ghost_memory") != null and obj.get_attrib("no_ghost", false) == false:
		if child is Sprite:
			child.material = ghost_material
		for subchild in child.get_children():
			if subchild is Sprite:
				subchild.material = ghost_material
	else:
		BehaviorEvents.emit_signal("OnStatusChanged", obj)
		var palette_path : String = obj.get_attrib("palette", "")
		if palette_path.empty() == true:
			palette_path = SelectRandomPalette(obj)
		if palette_path.empty() == false:
			obj.set_attrib("palette", palette_path)
			var palette_tex = load(Globals.clean_path(palette_path))
			if child is Sprite:
				#TODO: right now only sun has a palette and sun only has a single sprite.
				# If needed, do like ghost material and set children too
				child.material.set_shader_param("palette", palette_tex)
	
	
func sort_by_chance(a, b):
	if a.chance > b.chance:
		return true
	return false
	
func SelectRandomPalette(obj : Attributes) -> String:
	var palettes : Array = obj.get_attrib("palettes", [])
	if palettes.size() <= 0:
		return ""
	
	return MersenneTwister.rand_weight(palettes, "path", "chance", "")
	

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
		#print(sprite_level, " >= ", max_level, " at ", pos)
		return true
	else:
		#print(sprite_level, " >= ", max_level, " at ", pos)
		return false
		
