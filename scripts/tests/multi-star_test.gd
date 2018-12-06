#tool
extends Sprite

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export(Vector2) var size = Vector2(256,256) setget set_size
export(int) var num_star = 5 setget set_num_star
export(int) var star_seed = 2 setget set_seed
export(Color) var color = Color(1.0,1.0,1.0,1.0) setget set_color

func set_color(newval):
	color = newval
	_editor_refresh()
	
func set_size(newval):
	size = newval
	_editor_refresh()

func set_seed(newval):
	star_seed = newval
	_editor_refresh()

func set_num_star(newval):
	num_star = newval
	_editor_refresh()

func _editor_refresh():
	var tool_disabled = false
	if get_parent() != null and get_parent().has_method("tool_disabled") and get_parent().tool_disabled() == true:
		tool_disabled = true
	if get_parent() == null:
		tool_disabled = true
	if Engine.editor_hint and not tool_disabled:
		_refresh()
	
func _refresh():		
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()
    
	dynImage.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	_generate_star(dynImage)
    
	imageTexture.create_from_image(dynImage)
	self.texture = imageTexture
	imageTexture.resource_name = "The created texture!"
	
func _generate_star(dynImage):
	seed(star_seed)
	var stars = {}
	var col = color
	col.a = 0
	dynImage.fill(col)
	dynImage.lock()
	for i in range(num_star):
		var pos = Vector2(int(randf() * size.x), int(randf() * size.y))
		stars[pos] = 8-int(log(float(int(randf() * 1000)+1)))
		for x in range(pos.x-stars[pos], pos.x+stars[pos]):
			for y in range(pos.y-stars[pos], pos.y+stars[pos]):
				if x < 0 || x >= size.x:
					continue
				if y < 0 || y >= size.y:
					continue
				var xy = Vector2(x,y)
				var dist = (xy-pos).length()
				var dimness = -1.0 / float(stars[pos]) * float(dist) + 1.0
				dimness = clamp(dimness, 0.0, 1.0)
				col = dynImage.get_pixel(x, y)
				col.a = col.a + dimness
				dynImage.set_pixel(x, y, col)
	dynImage.unlock()
				
