extends Camera2D

export(float) var pan_smooth := -5
export(float) var follow_smooth : float
var _cur_vel := Vector2(0,0)
var _last_cam_pos := Vector2(0,0)

export(float) var max_zoom = 4.0
export(float) var min_zoom = 0.25
export(NodePath) var levelLoaderNode

var levelLoaderRef

var _touches = {} # for pinch zoom and drag with multiple fingers
var _touches_info = {"num_touch_last_frame":0, "radius":0, "total_pan":0}
var _debug_cur_touch = 0

var _zoomin : bool = false
var _zoomout : bool = false
var _enable_input : bool = false
var _keep_centered : bool = true

var _wait_for_anim = false

func _ready():
	var p = Globals.get_first_player()
	levelLoaderRef = get_node(levelLoaderNode)
	BehaviorEvents.connect("OnPlayerCreated", self, "OnPlayerCreated_callback")
	BehaviorEvents.connect("OnTransferPlayer", self, "OnTransferPlayer_callback")
	BehaviorEvents.connect("OnPlayerInputStateChanged", self, "OnPlayerInputStateChanged_callback")
	BehaviorEvents.connect("OnTeleport", self, "OnTeleport_callback")
	
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	
	BehaviorEvents.connect("OnPlayerDeath", self, "OnPlayerDeath_Callback")
	
	if has_node("../Camera-GUI/SafeArea/HUD_root/HUD/Buttons/ZoomIn"):
		var zoom_in_btn = get_node("../Camera-GUI/SafeArea/HUD_root/HUD/Buttons/ZoomIn")
		var zoom_out_btn = get_node("../Camera-GUI/SafeArea/HUD_root/HUD/Buttons/ZoomOut")
		zoom_in_btn.connect("down", self, "_on_ZoomIn_down")
		zoom_out_btn.connect("down", self, "_on_ZoomOut_down")
	
		zoom_in_btn.connect("up", self, "_on_Zoom_up")
		zoom_out_btn.connect("up", self, "_on_Zoom_up")
	
	if not Globals.is_mobile():
		zoom = Vector2(2.5, 2.5)
	
	
	if p != null:
		self.position = p.position
		_last_cam_pos = self.position
		
func OnWaitForAnimation_Callback():
	_wait_for_anim = true
	
func OnAnimationDone_Callback():
	_wait_for_anim = false
	
func OnPlayerDeath_Callback():
	var player = Globals.get_first_player()
	if player == null:
		return
	
	var tweener = get_node("Tween")
	
	var pos_time = 0.3
	var zoom_time = 2.0
	var target_value : Vector2 = player.position
	var target_zoom := Vector2(0.5,0.5)
	tweener.interpolate_property(
		self, 
		"position", 
		null,
		target_value,
		pos_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tweener.interpolate_property(
		self, 
		"zoom", 
		null,
		target_zoom,
		zoom_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tweener.start()
		
# Very ugly hack so that when we're in "look around" mode everything else is locked but the camera still handle inputs
func OnPlayerInputStateChanged_callback(playerObj, inputState):
	if inputState == Globals.INPUT_STATE.look_around:
		_enable_input = true
	else:
		_enable_input = false
		
func _input(event):
	if _enable_input == false:
		return
	
	_unhandled_input(event)

func _unhandled_input(event):
	if levelLoaderRef == null:
		return
		
	# Handle actual Multi-touch from capable devices
	if event is InputEventScreenTouch and event.pressed == true:
		_touches[event.index] = {"start":event, "current":event}
	if event is InputEventScreenTouch and event.pressed == false:
		_touches.erase(event.index)
	if event is InputEventScreenDrag:
		# if drag started on a button and the player dragged outside the button we won't get a ScreenTouch
		if not event.index in _touches:
			_touches[event.index] = {"start":event, "current":event}
		_touches[event.index]["current"] = event
		#update_pinch_gesture()

	# Handle Multi-touch using 'A' key and mouse event instead of Touch event	
	pretend_multi_touch(event)
	
	var key_str = ""
	if event is InputEventKey and event.unicode != 0:
		key_str = PoolByteArray([event.unicode]).get_string_from_utf8()
	
	# Wheel Up Event
	var zoom_factor :float = 0.0
	if event.is_action_pressed("zoom_in") or key_str == '+':
		zoom_factor = -1.5 * zoom.x
	# Wheel Down Event
	elif event.is_action_pressed("zoom_out") or key_str == '-':
		zoom_factor = 1.5 * zoom.x
		
	if zoom_factor != 0.0:
		_keep_centered = false
		var prev_zoom : Vector2 = zoom
		_zoom_camera(zoom_factor)
		var new_zoom : Vector2 = zoom
		if event is InputEventMouse and abs((prev_zoom - new_zoom).length_squared()) > 0.00001:
			var pos = event.position
			var vp_size = self.get_viewport().size
			if get_viewport().is_size_override_enabled():
				vp_size = get_viewport().get_size_override()
			var old_dist = ((event.position - (vp_size / 2.0))*prev_zoom)
			var new_dist = ((event.position - (vp_size / 2.0))*new_zoom)
			var cam_need_move = old_dist - new_dist
			self.position += cam_need_move

# Zoom Camera
func _zoom_camera(dir):
	zoom += Vector2(0.1, 0.1) * dir
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)
	BehaviorEvents.emit_signal("OnCameraZoomed", zoom)
	
func CenterCam(obj):
	var pos
	if obj is Node2D:
		pos = obj.position
	elif obj is Vector2:
		pos = obj
	self.position = pos
	_last_cam_pos = self.position
	reset_smooth()
		
func OnPlayerCreated_callback(var player):
	CenterCam(player)
	
func OnTransferPlayer_callback(old_player, new_player):
	CenterCam(new_player)
	
func OnTeleport_callback(obj, prev_tile, new_tile):
	if obj.get_attrib("type") == "player":
		_keep_centered = false # stop the camera smoothing toward the ship, we want to watch the teleport anim
		var old_pos : Vector2 = Globals.LevelLoaderRef.Tile_to_World(prev_tile)
		var prev_zoom : Vector2 = zoom
		CenterCam(old_pos)
		#zoom.x = 1.0
		#zoom.y = 1.0
		if _wait_for_anim == true:
			yield(BehaviorEvents, "OnAnimationDone")
		#CenterCam(obj)
		_keep_centered = true
		#zoom = prev_zoom

#func _on_ZoomIn_pressed():
#		_zoom_camera(-1)

#func _on_ZoomOut_pressed():
#		_zoom_camera(1)
	
func update_touch_info():
	if _touches.size() <= 0:
		_touches_info.num_touch_last_frame = _touches.size()
		_touches_info["total_pan"] = 0
		return
		
	if _touches_info["num_touch_last_frame"] == 0:
		reset_smooth()
		
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
	
	# hackish way to trigger OnCameraDragged only once per continuous touch
	if _touches_info["total_pan"] >= 0:
		var move : Vector2 = self.position - new_pos
		var vp_size = get_viewport().size
		move = move / vp_size
		_touches_info["total_pan"] += move.length()
		if _touches_info["total_pan"] > 0.1:
			BehaviorEvents.emit_signal("OnCameraDragged")
			_touches_info["total_pan"] = -1.0
		
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
	var final_zoom = zoom.x + zoom_factor

	zoom = Vector2(final_zoom,final_zoom)
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)
	BehaviorEvents.emit_signal("OnCameraZoomed", zoom)
		
	var vp_size = self.get_viewport().size
	if get_viewport().is_size_override_enabled():
		vp_size = get_viewport().get_size_override()
	var old_dist = ((_touches_info["target"] - (vp_size / 2.0))*(zoom-Vector2(zoom_factor, zoom_factor)))
	var new_dist = ((_touches_info["target"] - (vp_size / 2.0))*zoom)
	var cam_need_move = old_dist - new_dist
	self.position += cam_need_move
	
	#var to_print = "od.x %f, t.x %f, vp.x %f, zoom.x %f, fac %f, move.x(%f)" % [
	#	old_dist.x, _touches_info["target"].x, vp_size.x, zoom.x, zoom_factor, cam_need_move.x]
	#BehaviorEvents.emit_signal("OnLogLine", to_print)
	
func reset_smooth():
	_last_cam_pos = self.position
	_cur_vel = Vector2(0,0)
	
func _process(delta):
	if delta <= 0:
		return
		
	if not "player" in Globals.LevelLoaderRef.objByType or Globals.LevelLoaderRef.objByType["player"].size() <= 0:
		return
		
	if _zoomin == true:
		_zoom_camera(-20.0 * delta * zoom.x)
	if _zoomout == true:
		_zoom_camera(20.0 * delta * zoom.x)
		
	var target : Attributes = levelLoaderRef.objByType["player"][0]
	if target.get_attrib("animation.in_movement") == true or _keep_centered:
		#self.position = target.get_child(0).global_position
		_keep_centered = true
		smooth_goto(target.get_child(0).global_position, delta)
		_last_cam_pos = self.position
		align() # otherwise the camera viewport is updated one frame behind the position of the player, creating jerkiness
	#smooth_goto(target, delta)
		
	if _touches.size() > 0:
		_keep_centered = false
		update_vel(delta)
	if _touches.size() == 0:
		do_real_smoothing(delta)
			
		var bounds = levelLoaderRef.levelSize
		var tile_size = levelLoaderRef.tileSize
		var x : float = clamp(self.position.x, 0, bounds.x * tile_size)
		var y : float = clamp(self.position.y, 0, bounds.y * tile_size)
		self.position = Vector2(x,y)
	
func update_vel(delta : float):		
	var cur_cam_pos := self.position
	var move := _last_cam_pos - cur_cam_pos
	var move_speed : Vector2 = move / delta
	_cur_vel = (_cur_vel + move_speed) / 2.0
	_cur_vel.x = clamp(_cur_vel.x, -10000, 10000)
	_cur_vel.y = clamp(_cur_vel.y, -10000, 10000)
	_last_cam_pos = self.position
	
	#var bleh = "delta = %s, move (%d, %d), move_speed (%d,%d), _cur_vel (%d,%d)"
	#bleh = bleh % [str(delta), move.x, move.y, move_speed.x, move_speed.y, _cur_vel.x, _cur_vel.y]
	#print(bleh)
	
func do_real_smoothing(delta : float):
	var l = _cur_vel.length()
	var move_frame = 10 * exp(pan_smooth * ((log(l/10) / pan_smooth)+delta))
	_cur_vel = _cur_vel.normalized() * move_frame
	self.position -= _cur_vel * delta
	
func smooth_goto(target : Vector2, delta : float):
	var vec : Vector2 = target - self.position
	var l = vec.length()
	var move_frame = 10 * exp(follow_smooth * ((log(l/10) / follow_smooth)+delta))
	var total_move = vec.normalized() * move_frame * delta
	if total_move.length() > l:
		total_move = vec
	self.position += total_move
	
func _on_ZoomIn_down():
	_zoomin = true

func _on_ZoomOut_down():
	_zoomout = true

func _on_Zoom_up():
	_zoomin = false
	_zoomout = false
