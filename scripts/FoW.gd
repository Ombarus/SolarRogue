tool
extends Node2D

var _mesh : ArrayMesh

export(bool) var show_In_editor = false setget reset_set, reset_get

func reset_set(value):
	show_In_editor = value
	if value == true:
		_ready()
	else:
		_clear()
	
func reset_get():
	return show_In_editor

func _clear():
	get_node("MeshInstance2D").mesh = null

func _ready():
	_mesh = ArrayMesh.new()
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
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
	
	for c in range(levelSize.x):
		for r in range(levelSize.y):
			var lower_left := Vector3(c * tileSize - (tileSize/2.0), r * tileSize - (tileSize/2.0), 0.0)
			var upper_left := Vector3(lower_left.x, lower_left.y + tileSize, 0.0)
			var upper_right := Vector3(upper_left.x + tileSize, upper_left.y, 0.0)
			var lower_right := Vector3(upper_right.x, lower_left.y, 0.0)
			#print("lower_left (%.f,%.f), upper_left (%.f, %.f), upper_right (%.f, %.f), lower_right (%.f, %.f)" % [
			#	lower_left.x, lower_left.y,
			#	upper_left.x, upper_left.y,
			#	upper_right.x, upper_right.y,
			#	lower_right.x, lower_right.y
			#])
			var index_base = ((c*levelSize.y) + r) * 4
			var indice_index_base = ((c*levelSize.y) + r) * 6
			normal_array[index_base + 0] = Vector3(0, 0, 1)
			uv_array[index_base + 0] = Vector2(0,0)
			vertex_array[index_base + 0] = lower_left
			
			normal_array[index_base + 1] = Vector3(0, 0, 1)
			uv_array[index_base + 1] = Vector2(0,0.25)
			vertex_array[index_base + 1] = upper_left
			
			normal_array[index_base + 2] = Vector3(0, 0, 1)
			uv_array[index_base + 2] = Vector2(0.75,0.25)
			vertex_array[index_base + 2] = upper_right
			
			normal_array[index_base + 3] = Vector3(0, 0, 1)
			uv_array[index_base + 3] = Vector2(0.75,0)
			vertex_array[index_base + 3] = lower_right
			
			index_array[indice_index_base + 0] = index_base + 0
			index_array[indice_index_base + 1] = index_base + 1
			index_array[indice_index_base + 2] = index_base + 2
			index_array[indice_index_base + 3] = index_base + 2
			index_array[indice_index_base + 4] = index_base + 3
			index_array[indice_index_base + 5] = index_base + 0

	arrays[Mesh.ARRAY_VERTEX] = vertex_array
	arrays[Mesh.ARRAY_NORMAL] = normal_array
	arrays[Mesh.ARRAY_TEX_UV] = uv_array
	arrays[Mesh.ARRAY_INDEX] = index_array
	
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	get_node("MeshInstance2D").mesh = _mesh
	#VisualServer.set_debug_generate_wireframes(true)
	#get_viewport().debug_draw=get_viewport().DEBUG_DRAW_WIREFRAME
