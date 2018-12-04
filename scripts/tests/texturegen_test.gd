tool
extends Sprite

export(Vector2) var size = Vector2(256,256) setget set_size
export(int, 1, 1024, 1) var star_core_radius = 16 setget set_core_size
export(int, 1, 1024, 1) var glow_radius = 16 setget set_glow_radius
export(int, 0, 16) var spikes = 0 setget set_spikes
export(float) var spike_thickness = 2.0 setget set_spike_thick
export(int, 1, 1024, 1) var spike_radius = 16 setget set_spike_radius
export(Color) var color = Color(1.0,1.0,1.0,1.0) setget set_color

onready var sprite = self

func set_spike_radius(newval):
	spike_radius = newval
	_editor_refresh()

func set_spike_thick(newval):
	spike_thickness = newval
	_editor_refresh()

func set_glow_radius(newval):
	glow_radius = newval
	_editor_refresh()

func set_size(newval):
	size = newval
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

#func _ready():
#	_refresh()
	
func _editor_refresh():
	if Engine.editor_hint:
		_refresh()
	
func _refresh():
	if sprite == null:
		sprite = self
		
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()
    
	dynImage.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	dynImage.lock()
	_generate_star(dynImage)
	dynImage.unlock()
    
	imageTexture.create_from_image(dynImage)
	sprite.texture = imageTexture
	imageTexture.resource_name = "The created texture!"
	#imageTexture.path = "res://generated"
	
func _generate_star(dynImage):
	var center = size / 2
	var spikes_ar = []
	if spikes > 0:
		var deg_per_spike = 360.0 / float(spikes*2)
		for i in range(spikes):
			var spike = Vector2(0.0, 1.0)
			spike = spike.rotated(deg2rad(deg_per_spike * i))
			spikes_ar.push_back(spike)
			
	for y in range(size.y):
		for x in range(size.x):
			var xy = Vector2(x,y)
			if (xy - center).length() < star_core_radius:
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
				
				a = alpha_from_core(xy-center, glow_radius)
				
				if closest_spike != null:
					var proj_dist = (xy-center).dot(closest_spike)
					var dist_center = (xy-center).length()
					var a_on_spike = alpha_from_core(closest_spike * proj_dist, spike_radius)
					#linear
					#var a_on_thickness = -1.0 / float(spike_thickness) * float(closest_dist) + a_on_spike
					#exp
					var intensity = a_on_spike
					if closest_dist != 0:
						intensity = clamp(1 / pow(closest_dist, spike_thickness), 0, 1) * a_on_spike
					intensity = clamp(intensity, 0, 1)
					a = max(intensity, a)
				a = clamp(a, 0.0, 1.0)
				col.a = a
				dynImage.set_pixel(x, y, col)
	
func _distance_projected(var norm_line_at_origin, var point):
	var dist_proj = point.dot(norm_line_at_origin)
	var coord_p = norm_line_at_origin * dist_proj
	return (point - coord_p).length()
	
func alpha_from_core(var xy, radius):
	var dist_from_core_edge = (xy).length() - star_core_radius
	var a = -1.0 / float(radius) * float(dist_from_core_edge) + 1.0
	a = clamp(a, 0.0, 1.0)
	return a