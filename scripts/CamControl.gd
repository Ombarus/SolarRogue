extends Camera2D

export(float) var max_zoom = 4.0
export(float) var min_zoom = 0.25

var mouse_down = false
var start_touch_pos
var start_cam_pos

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	if mouse_down:
		var cur_pos = get_viewport().get_mouse_position()
		var deltap = start_touch_pos - cur_pos
		self.position = start_cam_pos + (deltap * self.zoom)

func _input(event):
	# Wheel Up Event
	if event.is_action_pressed("zoom_in"):
		_zoom_camera(-1)
	# Wheel Down Event
	elif event.is_action_pressed("zoom_out"):
		_zoom_camera(1)
	elif event.is_action_pressed("touch"):
		start_touch_pos = event.position
		start_cam_pos = self.position
		mouse_down = true
	
	
	if event.is_action_released("touch"):
		mouse_down = false

# Zoom Camera
func _zoom_camera(dir):
	zoom += Vector2(0.1, 0.1) * dir
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)
