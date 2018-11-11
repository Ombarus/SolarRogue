extends Control

func _ready():
	var grid_span = Globals.LevelLoaderRef.levelSize * Globals.LevelLoaderRef.tileSize
	self.rect_size = grid_span
	
func _draw():

	var tilemap_width = Globals.LevelLoaderRef.levelSize.x
	var tilemap_height = Globals.LevelLoaderRef.levelSize.y
	var line_color = Color(1.0, 1.0, 1.0, 1.0)
	var tile_size = Globals.LevelLoaderRef.tileSize
	
	draw_set_transform(Vector2(), 0, Vector2(tile_size, tile_size))

	for y in range(0, tilemap_height):
		draw_line(Vector2(-0.5, y-0.5), Vector2(tilemap_width-0.5, y-0.5), line_color)

	for x in range(0, tilemap_width):
		draw_line(Vector2(x-0.5, -0.5), Vector2(x-0.5, tilemap_height-0.5), line_color)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
