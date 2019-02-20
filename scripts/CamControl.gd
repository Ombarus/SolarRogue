extends Camera2D

export(float) var max_zoom = 4.0
export(float) var min_zoom = 0.25
export(NodePath) var levelLoaderNode

var levelLoaderRef
var mouse_down = false
var start_touch_pos
var start_cam_pos

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
		
	# Wheel Up Event
	if event.is_action_pressed("zoom_in"):
		_zoom_camera(-1)
	# Wheel Down Event
	elif event.is_action_pressed("zoom_out"):
		_zoom_camera(1)
	elif event.is_action_pressed("touch"):
		#start_touch_pos = event.position
		#start_cam_pos = self.position
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
		BehaviorEvents.emit_signal("OnCameraDragged")
	
	if event.is_action_released("touch"):
		mouse_down = false

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
