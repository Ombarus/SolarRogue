tool
extends Node2D

export(bool) var show_in_editor = false setget reset_set, reset_get

var _arrays := []
var _dirty_block = [Vector2(0, 0), Vector2(0, 0)]

func reset_set(value):
	if not Engine.editor_hint:
		return
	show_in_editor = value
	if value == true:
		_ready()
	else:
		_clear()
	
func reset_get():
	if not Engine.editor_hint:
		return
	return show_in_editor
	

const uv_lit = [Vector2(0.0, 0.25), Vector2(0.25, 0.0)]
const uv_explored_plain = [Vector2(0.25, 0.25), Vector2(0.5, 0.0)]
const uv_L_down_left = [Vector2(0.5, 0.25), Vector2(0.75, 0.0)]
const uv_L_up_left = [Vector2(0.75, 0.25), Vector2(1.0, 0.0)]
const uv_side_left = [Vector2(0.0, 0.5), Vector2(0.25, 0.25)]
const uv_up = [Vector2(0.25, 0.5), Vector2(0.5, 0.25)]
const uv_down = [Vector2(0.5, 0.5), Vector2(0.75, 0.25)]
const uv_corner_down_left = [Vector2(0.0, 0.75), Vector2(0.25, 0.5)]
const uv_corner_up_left = [Vector2(0.25, 0.75), Vector2(0.5, 0.5)]

func TagTile(tile : Vector2):
	_dirty_block[0] = Vector2(min(tile.x, _dirty_block[0].x), min(tile.y, _dirty_block[0].y))
	_dirty_block[1] = Vector2(max(tile.x, _dirty_block[1].x), max(tile.y, _dirty_block[1].y))
#const uv_lit = [Vector2(0.0, 0.25), Vector2(0.25, 0.0)]
#const uv_explored_plain = [Vector2(0.25, 0.25), Vector2(0.5, 0.0)]
#const uv_L_down_left = [Vector2(0.5, 0.25), Vector2(0.75, 0.0)]
#const uv_L_up_left = [Vector2(0.75, 0.25), Vector2(1.0, 0.0)]
#const uv_side_left = [Vector2(0.0, 0.5), Vector2(0.25, 0.25)]
#const uv_up = [Vector2(0.25, 0.5), Vector2(0.5, 0.25)]
#const uv_down = [Vector2(0.5, 0.5), Vector2(0.75, 0.25)]
#const uv_corner_down_left = [Vector2(0.0, 0.75), Vector2(0.25, 0.5)]
#const uv_corner_up_left = [Vector2(0.25, 0.75), Vector2(0.5, 0.5)]
	
func UpdateDirtyTiles(tile_memory : Array):
	var upper_left : Vector2 = _dirty_block[0]
	var lower_right : Vector2 = _dirty_block[1]
	var size : Vector2 = lower_right - upper_left
	if size.length_squared() <= 0.01:
		return
	
	for y in range(upper_left.y - 1, lower_right.y + 1):
		for x in range(upper_left.x - 1, lower_right.x + 1):
			var cur_tile := Vector2(x, y)
			_update_tile(tile_memory, cur_tile)
			
		
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	var mesh_instance = get_node("MeshInstance2D")
	mesh_instance.mesh = _mesh
	
func _update_tile(tile_memory : Array, tile : Vector2):
	
	# 255 is oppaque (not lit)
	# 0 is transparent (lit)
	#var tile_memory = _playerNode.get_attrib("memory." + level_id + ".tiles")
	#tile_memory[(((tile.y+1) * (Globals.LevelLoaderRef.levelSize.x+2)) + (tile.x+1))*4+0] = 0.0
	#tile_memory[(((tile.y+1) * (Globals.LevelLoaderRef.levelSize.x+2)) + (tile.x+1))*4+1] = 0.0
	#tile_memory[(((tile.y+1) * (Globals.LevelLoaderRef.levelSize.x+2)) + (tile.x+1))*4+2] = 0.0
	#tile_memory[(((tile.y+1) * (Globals.LevelLoaderRef.levelSize.x+2)) + (tile.x+1))*4+3] = 0.0
	
	#TODO: deal with boundaries!
	var l_lit : bool = tile_memory[_x_y_to_memory_index(tile.x - 1, tile.y)] == 0.0
	var r_lit : bool = tile_memory[_x_y_to_memory_index(tile.x + 1, tile.y)] == 0.0
	var u_lit : bool = tile_memory[_x_y_to_memory_index(tile.x, tile.y - 1)] == 0.0
	var d_lit : bool = tile_memory[_x_y_to_memory_index(tile.x, tile.y + 1)] == 0.0
	var dl_lit : bool = tile_memory[_x_y_to_memory_index(tile.x - 1, tile.y + 1)] == 0.0
	var ul_lit : bool = tile_memory[_x_y_to_memory_index(tile.x - 1, tile.y - 1)] == 0.0
	var ur_lit : bool = tile_memory[_x_y_to_memory_index(tile.x + 1, tile.y - 1)] == 0.0
	var dr_lit : bool = tile_memory[_x_y_to_memory_index(tile.x + 1, tile.y + 1)] == 0.0
	
	var is_lit : bool = l_lit && r_lit && u_lit && d_lit
	var is_plain : bool = not (is_lit)
	var is_l_down_left : bool = l_lit && d_lit && not r_lit && not u_lit
	var is_l_down_right : bool = r_lit && d_lit && not l_lit && not u_lit
	var is_l_up_left : bool = u_lit && l_lit && not r_lit && not d_lit
	var is_l_up_right : bool = u_lit && r_lit && not l_lit && not d_lit
	var is_side_right : bool = r_lit && not u_lit && not d_lit && not l_lit
	var is_side_left : bool = l_lit && not u_lit && not d_lit && not r_lit
	var is_side_up : bool = u_lit && not r_lit && not l_lit && not d_lit
	var is_side_down : bool = d_lit && not r_lit && not l_lit && not u_lit
	
	var index_base = _x_y_to_uv_index(tile)
	var uv_array = _arrays[Mesh.ARRAY_TEX_UV]
	
	if is_lit:
		uv_array[index_base + 0] = uv_lit[0] # lower_left
		uv_array[index_base + 1] = Vector2(uv_lit[1].x, uv_lit[0].y) # upper_left
		uv_array[index_base + 2] = uv_lit[1] # upper_right
		uv_array[index_base + 3] = Vector2(uv_lit[0].x, uv_lit[1].y) # lower_right
	elif is_plain:
		uv_array[index_base + 0] = uv_explored_plain[0] # lower_left
		uv_array[index_base + 1] = Vector2(uv_explored_plain[1].x, uv_explored_plain[0].y) # upper_left
		uv_array[index_base + 2] = uv_explored_plain[1] # upper_right
		uv_array[index_base + 3] = Vector2(uv_explored_plain[0].x, uv_explored_plain[1].y) # lower_right
	elif is_l_down_left:
		uv_array[index_base + 0] = uv_L_down_left[0] # lower_left
		uv_array[index_base + 1] = Vector2(uv_L_down_left[1].x, uv_L_down_left[0].y) # upper_left
		uv_array[index_base + 2] = uv_L_down_left[1] # upper_right
		uv_array[index_base + 3] = Vector2(uv_L_down_left[0].x, uv_L_down_left[1].y) # lower_right
	elif is_l_down_right:
		# Flipped X
		uv_array[index_base + 0] = Vector2(uv_L_down_left[0].x, uv_L_down_left[1].y) # lower_right
		uv_array[index_base + 1] = uv_L_down_left[1] # upper_right
		uv_array[index_base + 2] = Vector2(uv_L_down_left[1].x, uv_L_down_left[0].y) # upper_left
		uv_array[index_base + 3] = uv_L_down_left[0] # lower_left
	elif is_l_up_left:
		uv_array[index_base + 0] = uv_L_up_left[0] # lower_left
		uv_array[index_base + 1] = Vector2(uv_L_up_left[1].x, uv_L_up_left[0].y) # upper_left
		uv_array[index_base + 2] = uv_L_up_left[1] # upper_right
		uv_array[index_base + 3] = Vector2(uv_L_up_left[0].x, uv_L_up_left[1].y) # lower_right
	elif is_l_up_right:
		# Flipped X
		uv_array[index_base + 0] = Vector2(uv_L_up_left[0].x, uv_L_up_left[1].y) # lower_right
		uv_array[index_base + 1] = uv_L_up_left[1] # upper_right
		uv_array[index_base + 2] = Vector2(uv_L_up_left[1].x, uv_L_up_left[0].y) # upper_left
		uv_array[index_base + 3] = uv_L_up_left[0] # lower_left
	elif is_side_left:
		uv_array[index_base + 0] = uv_side_left[0] # lower_left
		uv_array[index_base + 1] = Vector2(uv_side_left[1].x, uv_side_left[0].y) # upper_left
		uv_array[index_base + 2] = uv_side_left[1] # upper_right
		uv_array[index_base + 3] = Vector2(uv_side_left[0].x, uv_side_left[1].y) # lower_right
	elif is_side_right:
		# Flipped X
		uv_array[index_base + 0] = Vector2(uv_side_left[0].x, uv_side_left[1].y) # lower_right
		uv_array[index_base + 1] = uv_side_left[1] # upper_right
		uv_array[index_base + 2] = Vector2(uv_side_left[1].x, uv_side_left[0].y) # upper_left
		uv_array[index_base + 3] = uv_side_left[0] # lower_left
	elif is_side_up:
		uv_array[index_base + 0] = uv_up[0] # lower_left
		uv_array[index_base + 1] = Vector2(uv_up[1].x, uv_up[0].y) # upper_left
		uv_array[index_base + 2] = uv_up[1] # upper_right
		uv_array[index_base + 3] = Vector2(uv_up[0].x, uv_up[1].y) # lower_right
	elif is_side_down:
		uv_array[index_base + 0] = uv_down[0] # lower_left
		uv_array[index_base + 1] = Vector2(uv_down[1].x, uv_down[0].y) # upper_left
		uv_array[index_base + 2] = uv_down[1] # upper_right
		uv_array[index_base + 3] = Vector2(uv_down[0].x, uv_down[1].y) # lower_right
		
	_arrays[Mesh.ARRAY_TEX_UV] = uv_array

func _clear():
	get_node("MeshInstance2D").mesh = null

func _x_y_to_memory_index(x, y):
	
	var levelSize := Vector2(80,80)
	var tileSize := 128
	if not Engine.editor_hint and Globals.LevelLoaderRef != null:
		levelSize = Globals.LevelLoaderRef.levelSize
		tileSize = Globals.LevelLoaderRef.tileSize
		
	return (((y+1) * (levelSize.x+2)) + (x+1))*4+0
	
func _x_y_to_uv_index(tile):
	var levelSize := Vector2(80,80)
	var tileSize := 128
	if not Engine.editor_hint and Globals.LevelLoaderRef != null:
		levelSize = Globals.LevelLoaderRef.levelSize
		tileSize = Globals.LevelLoaderRef.tileSize
		
	return ((tile.y*levelSize.x) + tile.x) * 4
	
var fake_tile_memory = []
func debug_init_fake_memory():
	var levelSize := Vector2(80,80)
	var tileSize := 128
	if not Engine.editor_hint and Globals.LevelLoaderRef != null:
		levelSize = Globals.LevelLoaderRef.levelSize
		tileSize = Globals.LevelLoaderRef.tileSize
	fake_tile_memory = []
	for x in range(levelSize.x + 2):
		for y in range(levelSize.y + 2):
			if x == 0 or y == 0 or x == levelSize.x+1 or y == levelSize.y + 1:
				fake_tile_memory.push_back(0.0) # having issues on iOS with R8 and gles2... trying to force RGBA8
				fake_tile_memory.push_back(0.0)
				fake_tile_memory.push_back(0.0)
				fake_tile_memory.push_back(0.0)
			else:
				fake_tile_memory.push_back(255.0)
				fake_tile_memory.push_back(255.0)
				fake_tile_memory.push_back(255.0)
				fake_tile_memory.push_back(255.0)

func _ready():
	debug_init_fake_memory()
	
	_arrays.resize(Mesh.ARRAY_MAX)
	var normal_array := PoolVector3Array()
	var uv_array := PoolVector2Array()
	var vertex_array := PoolVector3Array()
	var index_array := PoolIntArray()
	
	
	var levelSize := Vector2(80,80)
	var tileSize := 128
	if not Engine.editor_hint and Globals.LevelLoaderRef != null:
		levelSize = Globals.LevelLoaderRef.levelSize
		tileSize = Globals.LevelLoaderRef.tileSize
		
	var num_vertices : int = levelSize.x * levelSize.y * 4
	var num_indices : int = levelSize.x * levelSize.y * 6
	
	normal_array.resize(num_vertices)
	uv_array.resize(num_vertices)
	vertex_array.resize(num_vertices)
	index_array.resize(num_indices)
	
	for r in range(levelSize.x):
		for c in range(levelSize.y):
			var lower_left := Vector3(c * tileSize - (tileSize/2.0), r * tileSize - (tileSize/2.0), 0.0)
			var upper_left := Vector3(lower_left.x, lower_left.y + tileSize, 0.0)
			var upper_right := Vector3(upper_left.x + tileSize, upper_left.y, 0.0)
			var lower_right := Vector3(upper_right.x, lower_left.y, 0.0)
			var index_base = ((c*levelSize.x) + r) * 4
			var indice_index_base = ((c*levelSize.x) + r) * 6
			
			normal_array[index_base + 0] = Vector3(0, 0, 1)
			uv_array[index_base + 0] = Vector2(0.25,0.25)
			vertex_array[index_base + 0] = lower_left
			
			normal_array[index_base + 1] = Vector3(0, 0, 1)
			uv_array[index_base + 1] = Vector2(0.25,0.0)
			vertex_array[index_base + 1] = upper_left
			
			normal_array[index_base + 2] = Vector3(0, 0, 1)
			uv_array[index_base + 2] = Vector2(0.5,0.0)
			vertex_array[index_base + 2] = upper_right
			
			normal_array[index_base + 3] = Vector3(0, 0, 1)
			uv_array[index_base + 3] = Vector2(0.5,0.25)
			vertex_array[index_base + 3] = lower_right
			
			index_array[indice_index_base + 0] = index_base + 0
			index_array[indice_index_base + 1] = index_base + 1
			index_array[indice_index_base + 2] = index_base + 2
			index_array[indice_index_base + 3] = index_base + 2
			index_array[indice_index_base + 4] = index_base + 3
			index_array[indice_index_base + 5] = index_base + 0

	_arrays[Mesh.ARRAY_VERTEX] = vertex_array
	_arrays[Mesh.ARRAY_NORMAL] = normal_array
	_arrays[Mesh.ARRAY_TEX_UV] = uv_array
	_arrays[Mesh.ARRAY_INDEX] = index_array
	
	#yield(get_tree(), "idle_frame")
	
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	var mesh_instance = get_node("MeshInstance2D")
	mesh_instance.mesh = _mesh
	
var cur_x = 2
var t = 0.0

func _process(delta):
	t += delta
	if t < 1.0:
		return
		
	t = 0.0
	var tile = Vector2(cur_x, 2)
	var base_index = _x_y_to_memory_index(tile.x, tile.y)
	fake_tile_memory[base_index + 0] = 0.0
	fake_tile_memory[base_index + 1] = 0.0
	fake_tile_memory[base_index + 2] = 0.0
	fake_tile_memory[base_index + 3] = 0.0
	TagTile(Vector2(cur_x, 2))
	cur_x += 1
	UpdateDirtyTiles(fake_tile_memory)
	
