extends Camera2D

export(float) var max_zoom = 4.0
export(float) var min_zoom = 0.25
export(NodePath) var levelLoaderNode

var levelLoaderRef

var _touches = {} # for pinch zoom and drag with multiple fingers
var _touches_info = {"num_touch_last_frame":0, "radius":0, "total_pan":0}
var _debug_cur_touch = 0

func _ready():
	levelLoaderRef = get_node(levelLoaderNode)
	var p = levelLoaderRef.objByType["player"][0]
	self.position = p.position
	BehaviorEvents.connect("OnMovement", self, "OnMovement_callback")
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_callback")

func _unhandled_input(event):
	if levelLoaderRef == null:
		return
		
	# Handle actual Multi-touch from capable devices
	if event is InputEventScreenTouch and event.pressed == true:
		_touches[event.index] = {"start":event, "current":event}
	if event is InputEventScreenTouch and event.pressed == false:
		_touches.erase(event.index)
	if event is InputEventScreenDrag:
		_touches[event.index]["current"] = event
		update_pinch_gesture()

	# Handle Multi-touch using 'A' key and mouse event instead of Touch event	
	pretend_multi_touch(event)
	
	# Wheel Up Event
	if event.is_action_pressed("zoom_in"):
		print(event.position)
		_zoom_camera(-1)
	# Wheel Down Event
	elif event.is_action_pressed("zoom_out"):
		_zoom_camera(1)

# Zoom Camera
func _zoom_camera(dir):
	zoom += Vector2(0.1, 0.1) * dir
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)
	
func OnMovement_callback(obj, dir):
	if obj.get_attrib("type") == "player":
		self.position = obj.position
		
func OnLevelLoaded_callback():
	OnMovement_callback(levelLoaderRef.objByType["player"][0], null)
	
func OnTransferPlayer_callback(old_player, new_player):
	OnMovement_callback(new_player, null)

func _on_ZoomIn_pressed():
	_zoom_camera(-1)

func _on_ZoomOut_pressed():
	_zoom_camera(1)
	
func update_touch_info():
	if _touches.size() <= 0:
		_touches_info.num_touch_last_frame = _touches.size()
		_touches_info["total_pan"] = 0
		return
		
	var avg_touch = Vector2(0,0)
	for key in _touches:
		avg_touch += _touches[key].current.position
	_touches_info["cur_pos"] = avg_touch / _touches.size()
	if _touches_info.num_touch_last_frame != _touches.size():
		_touches_info["target"] = _touches_info["cur_pos"]
			
	_touches_info.num_touch_last_frame = _touches.size()
	
	do_multitouch_pan()
		
func do_multitouch_pan():
	var diff = _touches_info.target - _touches_info.cur_pos
	
	var new_pos = self.position + (diff * zoom.x)
	
	var bounds = levelLoaderRef.levelSize
	var tile_size = levelLoaderRef.tileSize
	if new_pos.x < 0 or new_pos.x > (bounds.x * tile_size):
		new_pos.x = self.position.x
	if new_pos.y < 0 or new_pos.y > (bounds.y * tile_size):
		new_pos.y = self.position.y
		
	_touches_info["total_pan"] += (self.position - new_pos).length()
	var move_trigger = 256.0
	if _touches_info["total_pan"] > move_trigger:
		BehaviorEvents.emit_signal("OnCameraDragged")
		
	self.position = new_pos
	
	_touches_info.target = _touches_info.cur_pos

func pretend_multi_touch(event):
	if event is InputEventKey and event.scancode == KEY_A:
		if event.pressed:
			if _debug_cur_touch == 0:
				_debug_cur_touch = 1
		else:
			if _debug_cur_touch == 1:
				_debug_cur_touch = 0
	if event is InputEventMouseButton:
		if event.pressed:
			_touches[_debug_cur_touch] = {"start":event, "current":event}
		else:
			_touches.erase(_debug_cur_touch)
	if event is InputEventMouseMotion:
		if _debug_cur_touch in _touches:
			_touches[_debug_cur_touch]["current"] = event
			
	update_touch_info()
	update_pinch_gesture()
			

func update_pinch_gesture():
	if _touches.size() < 2:
		_touches_info["radius"] = 0
		_touches_info["previous_radius"] = 0
		return

	_touches_info["previous_radius"] = _touches_info["radius"]
	_touches_info["radius"] = (_touches.values()[0].current.position - _touches_info["target"]).length()

	if _touches_info["previous_radius"] == 0:
		return
	
	var zoom_factor = (_touches_info["previous_radius"] - _touches_info["radius"]) / _touches_info["previous_radius"]
	zoom_factor = zoom.x + zoom_factor

	zoom = Vector2(zoom_factor,zoom_factor)
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)