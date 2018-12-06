tool
extends Sprite

export(bool) var debug_refresh = false setget set_debug

export(int) var texture_size = 256
export(int) var random_seed = 2 setget set_seed
export(Vector2) var num_stars = Vector2(1, 50) setget set_num_stars

export(Vector2) var star_core_radius = Vector2(1.0,8.0) setget set_core_size
export(Vector2) var glow_radius = Vector2(0.9, 300.0) setget set_glow_radius
export(Vector2) var spikes = Vector2(0.0, 16.0) setget set_spikes
export(Vector2) var spike_thickness = Vector2(0.8, 300.0) setget set_spike_thick
export(Vector2) var spike_radius = Vector2(0.7,1.3) setget set_spike_radius
export(float) var spike_percent = 0.1 setget set_spike_percent
export(Color) var color = Color(1.0,1.0,1.0,1.0) setget set_color

func set_debug(newval):
	debug_refresh = newval
	if debug_refresh == true:
		Refresh()
	else:
		self.texture = null

func set_num_stars(newval):
	num_stars = newval
	_editor_refresh()
		
func set_seed(newval):
	random_seed = newval
	_editor_refresh()
		
func set_spike_percent(newval):
	spike_percent = newval
	_editor_refresh()
		
func set_spike_radius(newval):
	spike_radius = newval
	_editor_refresh()

func set_spike_thick(newval):
	spike_thickness = newval
	_editor_refresh()

func set_glow_radius(newval):
	glow_radius = newval
	_editor_refresh()

func set_core_size(newval):
	star_core_radius = newval
	_editor_refresh()
	
func set_spikes(newval):
	spikes = newval
	_editor_refresh()
	
func set_color(newval):
	color = newval
	_editor_refresh()

func _editor_refresh():
	if debug_refresh == true:
		Refresh()

func _ready():
	Refresh()
	pass

func Refresh():
	seed(random_seed)
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()
    
	dynImage.create(texture_size,texture_size,false,Image.FORMAT_RGBA8)
	dynImage.fill(Color(color.r, color.g, color.b, 0.0))
	dynImage.lock()
	_generate_star(dynImage)
	dynImage.unlock()
    
	imageTexture.create_from_image(dynImage)
	self.texture = imageTexture
	imageTexture.resource_name = "The created texture!"
	#imageTexture.path = "res://generated"
	
func _generate_star(dynImage):
	var rnd = randf()
	#var minus = spikes[1]-spikes[0]
	var spike_count = (randf() * (spikes[1]-spikes[0])) + spikes[0]
	var star_count = int((randf() * (num_stars[1]-num_stars[0])) + num_stars[0])
	#print("rnd = ", rnd, ", minus = ", minus, ", spike_count = ", spike_count)
	spike_count = int(spike_count)
	var spikes_ar = []
	if spike_count > 0:
		var deg_per_spike = 360.0 / float(spike_count*2)
		for i in range(spike_count):
			var spike = Vector2(0.0, 1.0)
			spike = spike.rotated(deg2rad(deg_per_spike * i))
			spikes_ar.push_back(spike)
	
	for i in range(star_count):
		var data = _get_randomized_star_info()
		var center = data["center"]
		for y in range(texture_size):
			for x in range(texture_size):
				var xy = Vector2(x,y)
				if (xy - center).length() < data["star_core_radius"]:
					dynImage.set_pixel(x, y, color)
				else:
					var col = color
					var closest_spike = null
					var closest_dist = 0
					var a = 0
					for s in spikes_ar:
						var dist_proj = _distance_projected(s, xy-center)
						if closest_spike == null or dist_proj < closest_dist:
							closest_dist = dist_proj
							closest_spike = s
					
					a = alpha_from_core(xy-center, data["star_core_radius"], data["glow_radius"])
					if data["has_spike"] == false:
						closest_spike = null
					
					if closest_spike != null:
						var proj_dist = (xy-center).dot(closest_spike)
						var dist_center = (xy-center).length()
						var a_on_spike = alpha_from_core(closest_spike * proj_dist, data["star_core_radius"], data["spike_radius"])
						#linear
						#var a_on_thickness = -1.0 / float(spike_thickness) * float(closest_dist) + a_on_spike
						#exp
						var intensity = a_on_spike
						if closest_dist != 0 and (data["spike_thickness"] < 100 or closest_dist >= 1.0):
							intensity = clamp(1 / pow(closest_dist, data["spike_thickness"]), 0, 1) * a_on_spike
						intensity = clamp(intensity, 0, 1)
						a = max(intensity, a)
					a = clamp(a, 0.0, 1.0)
					col = dynImage.get_pixel(x,y)
					col.a += a
					dynImage.set_pixel(x, y, col)
	
func _get_randomized_star_info():
	var data = {}
	#star_core_radius = Vector2(1,8) setget set_core_size
	#glow_radius = Vector2(0.9, 300.0) setget set_glow_radius
	#spikes = Vector2(0, 16) setget set_spikes
	#spike_thickness = Vector2(0.8, 300.0) setget set_spike_thick
	#spike_radius = Vector2(0.7,1.3) setget set_spike_radius
	data["star_core_radius"] = int((randf() * (star_core_radius[1]-star_core_radius[0])) + star_core_radius[0])
	data["glow_radius"] = (randf() * (glow_radius[1]-glow_radius[0])) + glow_radius[0]
	data["spike_thickness"] = (randf() * (spike_thickness[1]-spike_thickness[0])) + spike_thickness[0]
	data["spike_radius"] = (randf() * (spike_radius[1]-spike_radius[0])) + spike_radius[0]
	data["center"] = Vector2(int((randf() * texture_size)), int((randf() * texture_size)))
	data["has_spike"] = randf() < spike_percent
	return data
	
func _distance_projected(var norm_line_at_origin, var point):
	var dist_proj = point.dot(norm_line_at_origin)
	var coord_p = norm_line_at_origin * dist_proj
	return (point - coord_p).length()
	
func alpha_from_core(var xy, star_radius, radius):
	var dist_from_core_edge = (xy).length() - star_radius
	#var a = -1.0 / float(radius) * float(dist_from_core_edge) + 1.0
	var a = 1.0
	if dist_from_core_edge > 0 and (radius < 100 or dist_from_core_edge >= 1.0):
		a = clamp(1 / pow(dist_from_core_edge, radius), 0, 1)
	a = clamp(a, 0.0, 1.0)
	return a