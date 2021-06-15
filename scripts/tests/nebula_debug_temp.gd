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
	
func _process(delta):
	var t = get_viewport().canvas_transform
	t.translated(Vector2(100.0, 100.0))
	tilemap.material.set_shader_param("camera_view", t)
	print(tilemap.material.get_shader_param("camera_view"))

func regen():
	var level_size : Vector2 = Globals.LevelLoaderRef.levelSize
	var tile_offset = Globals.LevelLoaderRef.World_to_Tile(get_global_transform().origin)
	for x in range(map_size):
		if x + tile_offset.x < -1 or x + tile_offset.x > level_size.x:
			continue
		for y in range(map_size):
			if y + tile_offset.y < -1 or y + tile_offset.y > level_size.y:
				continue
			var f : float = noise_func.get_noise_2d(x, y) + 1.0 / 2.0
			var amplitude : float = calculate_amplitude(x, y)
			var index : int = -1
			f *= amplitude
			if f >= noise_floor:
				index = 0
			tilemap.set_cell ( x, y, index )
			
	tilemap.set_cell(0, 0, 0)
	tilemap.set_cell(map_size, map_size, 0)
			
	tilemap.update_bitmask_region ( Vector2.ZERO, Vector2(map_size,map_size) )

func calculate_amplitude(x, y) -> float:
	var coord_centered := Vector2(x-map_size/2.0,y-map_size/2.0)
	var length := clamp(coord_centered.length(), 0.0, map_size/2.0)
	var normalized = length / (map_size/2.0)
	var result = -pow(normalized, exponent) + 1.0
	return result
	
func clear():
	for x in range(map_size):
		for y in range(map_size):
			tilemap.set_cell ( x, y, -1 )
