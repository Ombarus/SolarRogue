extends Node

export(NodePath) var levelLoaderNode

var playerNode = null
var levelLoaderRef

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	levelLoaderRef = get_node(levelLoaderNode)
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	
	
func OnLevelLoaded_Callback():
	if playerNode == null:
		var starting_wormhole = null
		for w in levelLoaderRef.objByType["wormhole"]:
			if starting_wormhole == null || w.modified_attributes["depth"] < starting_wormhole.modified_attributes["depth"]:
				starting_wormhole = w
				
		#TODO: Pop menu for player creation ?
		playerNode = levelLoaderRef.RequestObject("data/json/ships/player_default.json", levelLoaderRef.World_to_Tile(starting_wormhole.position))
		
	
func _input(event):
	var dir = null
	if event is InputEventMouseButton:
		if event.is_action_released("touch"):
			pass
			# Calculate direction based on touch relative to player position.
	if event is InputEventKey && event.pressed == false:
		if event.scancode == KEY_KP_1:
			dir = Vector2(-1,1)
		if event.scancode == KEY_KP_2:
			dir = Vector2(0,1)
		if event.scancode == KEY_KP_3:
			dir = Vector2(1,1)
		if event.scancode == KEY_KP_4:
			dir = Vector2(-1,0)
		if event.scancode == KEY_KP_6:
			dir = Vector2(1,0)
		if event.scancode == KEY_KP_7:
			dir = Vector2(-1,-1)
		if event.scancode == KEY_KP_8:
			dir = Vector2(0,-1)
		if event.scancode == KEY_KP_9:
			dir = Vector2(1,-1)
	if dir != null:
		BehaviorEvents.emit_signal("OnMovement", playerNode, dir)
#		_zoom_camera(-1)
#	# Wheel Down Event
#	elif event.is_action_pressed("zoom_out"):
#		_zoom_camera(1)
#	elif event.is_action_pressed("touch"):
#		start_touch_pos = event.position
#		start_cam_pos = self.position
#		mouse_down = true
#	
#	
#	if event.is_action_released("touch"):
#		mouse_down = false

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
