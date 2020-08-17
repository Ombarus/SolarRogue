#tool
extends Node2D


export(bool) var show_in_editor = false setget reset_set, reset_get

func reset_set(value):
	if not Engine.editor_hint:
		return
	show_in_editor = value
	if value == true:
		_ready()
	else:
		var _occluder_ref = get_node("Occlusion")
		_occluder_ref.texture = null
	
func reset_get():
	if not Engine.editor_hint:
		return
	return show_in_editor

var mem = null
var explored_mem = null
var t := 0.0
var is_tag := false

func _ready():
	_tag_tile(Vector2(2, 2))
	_tag_tile(Vector2(2, 3))
	_tag_tile(Vector2(2, 4))
	_tag_tile(Vector2(3, 2))
	_tag_tile(Vector2(3, 3))
	_tag_tile(Vector2(3, 4))
	_tag_tile(Vector2(4, 2))
	_tag_tile(Vector2(4, 3))
	_tag_tile(Vector2(4, 4))
	_tag_tile(Vector2(2, 2), false, true)
	_update_occlusion_texture()
	_update_occlusion_texture(true)


func _tag_tile(tile, untag=false, explored=false):
	
	var levelSize := Vector2(80,80)
	var tileSize := 128
	if not Engine.editor_hint and Globals.LevelLoaderRef != null:
		levelSize = Globals.LevelLoaderRef.levelSize
		tileSize = Globals.LevelLoaderRef.tileSize
	
	var tile_memory = null
	if explored:
		tile_memory = explored_mem
	else:
		tile_memory = mem
	if tile_memory == null:
		tile_memory = []
		for x in range(levelSize.x + 2):
			for y in range(levelSize.y + 2):
				if x == 0 or y == 0 or x == levelSize.x+1 or y == levelSize.y + 1:
					tile_memory.push_back(0.0) # having issues on iOS with R8 and gles2... trying to force RGBA8
					tile_memory.push_back(0.0)
					tile_memory.push_back(0.0)
					tile_memory.push_back(0.0)
				else:
					tile_memory.push_back(255.0)
					tile_memory.push_back(255.0)
					tile_memory.push_back(255.0)
					tile_memory.push_back(255.0)
	
	if untag == false:	
		tile_memory[(((tile.y+1) * (levelSize.x+2)) + (tile.x+1))*4+0] = 0.0
		tile_memory[(((tile.y+1) * (levelSize.x+2)) + (tile.x+1))*4+1] = 0.0
		tile_memory[(((tile.y+1) * (levelSize.x+2)) + (tile.x+1))*4+2] = 0.0
		tile_memory[(((tile.y+1) * (levelSize.x+2)) + (tile.x+1))*4+3] = 0.0
	else:
		tile_memory[(((tile.y+1) * (levelSize.x+2)) + (tile.x+1))*4+0] = 255.0
		tile_memory[(((tile.y+1) * (levelSize.x+2)) + (tile.x+1))*4+1] = 255.0
		tile_memory[(((tile.y+1) * (levelSize.x+2)) + (tile.x+1))*4+2] = 255.0
		tile_memory[(((tile.y+1) * (levelSize.x+2)) + (tile.x+1))*4+3] = 255.0
		
	
	if explored:
		explored_mem = tile_memory
	else:
		mem = tile_memory
	
func _update_occlusion_texture(explored=false):
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()
	
	var levelSize := Vector2(80,80)
	var tileSize := 128
	if not Engine.editor_hint and Globals.LevelLoaderRef != null:
		levelSize = Globals.LevelLoaderRef.levelSize
		tileSize = Globals.LevelLoaderRef.tileSize
	
	var tile_memory = null
	if explored:
		tile_memory = explored_mem
	else:
		tile_memory = mem
	if tile_memory == null:
		dynImage.create(levelSize.x+2,Globals.LevelLoaderRef.levelSize.y+2,false,Image.FORMAT_RGBA8)
		dynImage.fill(Color(1.0,1.0,1.0,1.0))
	else:
		dynImage.create_from_data(levelSize.x+2,levelSize.y+2,false,Image.FORMAT_RGBA8, tile_memory)
	
	imageTexture.create_from_image(dynImage)
	var _occluder_ref = null
	if explored:
		_occluder_ref = get_node("Explored")
	else:
		_occluder_ref = get_node("Occlusion")
	_occluder_ref.texture = imageTexture
	imageTexture.resource_name = "The created texture!"
	
	
func _process(delta):
	if t < 0.3:
		t += delta
		return
	else:
		t = 0.0
	
	for x in range(10):
		for y in range(10):
			_tag_tile(Vector2(x+2, y+2), is_tag)
	
	for x in range(10):
		for y in range(10):
			_tag_tile(Vector2(x+2, y+2), not is_tag, true)
			
			
	_update_occlusion_texture()
	_update_occlusion_texture(true)
	is_tag = not is_tag
	
