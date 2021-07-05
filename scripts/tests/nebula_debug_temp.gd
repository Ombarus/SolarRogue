extends Node2D
class_name NebulaGenerator

export(OpenSimplexNoise) var noise_func : OpenSimplexNoise
export(int) var map_size : int
export(float, -1.0, 1.0) var noise_floor : float
export(float) var exponent : float

onready var tilemap : TileMap = $Nebula2/TileMap

func Init(noise_seed : int, nebula_range : int):
	noise_func.seed = noise_seed
	map_size = nebula_range
	regen()
	
func get_cellv(coord : Vector2):
	return tilemap.get_cellv(coord)
	
func _process(delta):
	# final_transform seems to only contain the stretch from resizing the window
	# and canvas_transform seems to be the view matrix
	#print(get_viewport_transform())
	var t = get_viewport_transform()#get_viewport().get_final_transform() * get_viewport().canvas_transform
	tilemap.material.set_shader_param("camera_view", t)

func regen():
	var level_size : Vector2 = Globals.LevelLoaderRef.levelSize
	var tile_offset : Vector2 = Globals.LevelLoaderRef.World_to_Tile(get_global_transform().origin)
	for x in range(map_size):
		var center_x = x - (map_size/2.0)
		if center_x + tile_offset.x < -1 or center_x + tile_offset.x > level_size.x:
			continue
		for y in range(map_size):
			var center_y = y - (map_size/2.0)
			if center_y + tile_offset.y < -1 or center_y + tile_offset.y > level_size.y:
				continue
			var f : float = noise_func.get_noise_2d(center_x, center_y) + 1.0 / 2.0
			var amplitude : float = calculate_amplitude(center_x, center_y)
			var index : int = -1
			f *= amplitude
			if f >= noise_floor:
				index = 0
			tilemap.set_cell ( center_x, center_y, index )
			
	tilemap.set_cell(0, 0, 0)
	tilemap.set_cell(map_size, map_size, 0)
			
	tilemap.update_bitmask_region ( Vector2.ZERO, Vector2(-map_size/2.0,map_size/2.0) )

func calculate_amplitude(x, y) -> float:
	var coord_centered := Vector2(x,y)
	var length := clamp(coord_centered.length(), 0.0, map_size/2.0)
	var normalized = length / (map_size/2.0)
	var result = -pow(normalized, exponent) + 1.0
	return result
	
func clear():
	for x in range(map_size):
		for y in range(map_size):
			tilemap.set_cell ( x, y, -1 )
