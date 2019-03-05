extends Camera2D

export(float) var max_zoom = 4.0
export(float) var min_zoom = 0.25
export(NodePath) var levelLoaderNode

var levelLoaderRef
var mouse_down = false
var start_touch_pos
var start_cam_pos
var _orig_dist = 0 # for two-finger pinch distance between both finger

var _touches = {} # for pinch zoom and drag with multiple fingers
var _debug_cur_touch = 0

func _ready():
	levelLoaderRef = get_node(levelLoaderNode)
	var p = levelLoaderRef.objByType["player"][0]
	self.position = p.position
	BehaviorEvents.connect("OnMovement", self, "OnMovement_callback")
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_callback")

func _process(delta):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	pass
	#if mouse_down:
	#	var cur_pos = get_viewport().get_mouse_position()
	#	var deltap = start_touch_pos - cur_pos
	#	self.position = start_cam_pos + (deltap * self.zoom)

func _unhandled_input(event):
	if levelLoaderRef == null:
		return
		
	
	#if event is InputEventScreenTouch and event.pressed == true:
	#	_touches[event.index] = event
	#if event is InputEventScreenTouch and event.pressed == false:
	#	_touches.erase(event.index)
	#if event is InputEventScreenDrag and _touches.size() == 2:
	#	_zoom_camera(-1)
	
	#if event is InputEventMagnifyGesture:
	#	_zoom_camera(event.factor)
		
		
	pretend_multi_touch(event)
	
	"""
	# Wheel Up Event
	if event.is_action_pressed("zoom_in"):
		print(event.position)
		_zoom_camera(-1)
	# Wheel Down Event
	elif event.is_action_pressed("zoom_out"):
		_zoom_camera(1)
	elif event.is_action_pressed("touch"):
		#start_touch_pos = event.position
		mouse_down = true
	elif event is  InputEventMouseMotion and mouse_down == true:
		var new_pos = self.position - (event.relative * self.zoom)
		var bounds = levelLoaderRef.levelSize
		var tile_size = levelLoaderRef.tileSize
		if new_pos.x < 0 or new_pos.x > (bounds.x * tile_size):
			new_pos.x = self.position.x
		if new_pos.y < 0 or new_pos.y > (bounds.y * tile_size):
			new_pos.y = self.position.y
		self.position = new_pos
		
		if start_cam_pos != null:
			var drag_vec = start_cam_pos - self.position
			var move_trigger = 256.0
			move_trigger *= move_trigger
			if drag_vec.length_squared() > move_trigger:
				BehaviorEvents.emit_signal("OnCameraDragged")
		
	
	if event.is_action_released("touch"):
		mouse_down = false
	"""

# Zoom Camera
func _zoom_camera(dir):
	zoom += Vector2(0.1, 0.1) * dir
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)
	
func OnMovement_callback(obj, dir):
	if obj.get_attrib("type") == "player":
		self.position = obj.position
		start_cam_pos = self.position
		
func OnLevelLoaded_callback():
	OnMovement_callback(levelLoaderRef.objByType["player"][0], null)
	
func OnTransferPlayer_callback(old_player, new_player):
	OnMovement_callback(new_player, null)

func _on_ZoomIn_pressed():
	_zoom_camera(-1)

func _on_ZoomOut_pressed():
	_zoom_camera(1)

func pretend_multi_touch(event):
	if event is InputEventKey and event.scancode == KEY_A:
		if event.pressed:
			if _debug_cur_touch == 0:
				_debug_cur_touch = 1
		else:
			if _debug_cur_touch == 1:
				_debug_cur_touch = 0
		#print(_debug_cur_touch)
	if event is InputEventMouse:
		pass
	if event is InputEventMouseButton:
		if event.pressed:
			_touches[_debug_cur_touch] = {"start":event}
		else:
			_touches.erase(_debug_cur_touch)
	if event is InputEventMouseMotion:
		if _debug_cur_touch in _touches:
			_touches[_debug_cur_touch]["current"] = event
			update_pinch_gesture()
			
func update_pinch_gesture():
	if _touches.size() < 2:
		return
	
	var start = (_touches[0].start.position - _touches[1].start.position)
	var cur = (_touches[0].current.position - _touches[1].current.position)
	var start_dist = start.length()
	var cur_dist = cur.length()
	
	var zoom_factor = (start_dist - cur_dist) / start_dist
	var zoom_factor_2d = (start - cur) / start
	zoom = Vector2(zoom_factor_2d)
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)