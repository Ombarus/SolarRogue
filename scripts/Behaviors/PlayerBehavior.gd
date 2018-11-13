extends Node

export(NodePath) var levelLoaderNode
export(NodePath) var WeaponAction
export(NodePath) var GrabAction
export(NodePath) var DropAction

var playerNode = null
var levelLoaderRef
var click_start_pos
var lock_input = false # when it's not player turn, inputs are locked

enum INPUT_STATE {
	hud,
	grid_targetting,
	cell_targetting
}
var _input_state = INPUT_STATE.hud

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	levelLoaderRef = get_node(levelLoaderNode)
	
	var action = get_node(WeaponAction)
	action.connect("pressed", self, "Pressed_Weapon_Callback")
	action = get_node(GrabAction)
	action.connect("pressed", self, "Pressed_Grab_Callback")
	action = get_node(DropAction)
	action.connect("pressed", self, "Pressed_Drop_Callback")
	
	BehaviorEvents.connect("OnLevelLoaded", self, "OnLevelLoaded_Callback")
	BehaviorEvents.connect("OnObjTurn", self, "OnObjTurn_Callback")
	
func Pressed_Grab_Callback():
	if lock_input:
		return
		
	BehaviorEvents.emit_signal("OnPickup", playerNode, Globals.LevelLoaderRef.World_to_Tile(playerNode.position))
	
func Pressed_Drop_Callback():
	if lock_input:
		return
		
	BehaviorEvents.emit_signal("OnPushGUI", "Inventory")
	
	
func OnObjTurn_Callback(obj):
	print("Player OnObjTurn_Callback")
	if obj.base_attributes.type == "player":
		lock_input = false
	else:
		lock_input = true
	
func Pressed_Weapon_Callback():
	if lock_input:
		return
		
	BehaviorEvents.emit_signal("OnLogLine", "Weapon System Online. Target ?")
	BehaviorEvents.emit_signal("OnPushGUI", "GridPattern")
	_input_state = INPUT_STATE.grid_targetting
	
func OnLevelLoaded_Callback():
	if playerNode == null:
		var starting_wormhole = null
		for w in levelLoaderRef.objByType["wormhole"]:
			if starting_wormhole == null || w.modified_attributes["depth"] < starting_wormhole.modified_attributes["depth"]:
				starting_wormhole = w
				
		#TODO: Pop menu for player creation ?
		playerNode = levelLoaderRef.RequestObject("data/json/ships/player_default.json", levelLoaderRef.World_to_Tile(starting_wormhole.position))
		
	
func _unhandled_input(event):
	if lock_input:
		return
		
	var dir = null
	if event is InputEventMouseButton:
		if event.is_action_pressed("touch"):
			click_start_pos = event.position
		if event.is_action_released("touch") && (click_start_pos - event.position).length_squared() < 5.0:
			var click_pos = playerNode.get_global_mouse_position()
			
			if _input_state == INPUT_STATE.grid_targetting:
				ProcessGridSelection(click_pos)
			else:
				var player_pos = playerNode.position
				var click_dir = click_pos - player_pos
				var rot = rad2deg(Vector2(0.0, 0.0).angle_to_point(click_dir)) - 90.0
				if rot < 0:
					rot += 360
				print("player_pos ", player_pos, ", click_pos ", click_pos, ", rot ", rot)
				
				# Calculate direction based on touch relative to player position.
				# dead zone (click on sprite)
				if abs(click_dir.x) < levelLoaderRef.tileSize / 2 && abs(click_dir.y) < levelLoaderRef.tileSize / 2:
					dir = null
				elif rot > 337.5 || rot <= 22.5:
					dir = Vector2(0,-1) # 8
				elif rot > 22.5 && rot <= 67.5:
					dir = Vector2(1,-1) # 9
				elif rot > 67.5 && rot <= 112.5:
					dir = Vector2(1,0) # 6
				elif rot > 112.5 && rot <= 157.5:
					dir = Vector2(1,1) # 3
				elif rot > 157.5 && rot <= 202.5:
					dir = Vector2(0,1) # 2
				elif rot > 202.5 && rot <= 247.5:
					dir = Vector2(-1,1) # 1
				elif rot > 247.5 && rot <= 292.5:
					dir = Vector2(-1,0) # 4
				elif rot > 292.5 && rot <= 337.5:
					dir = Vector2(-1,-1) # 7
				
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

func ProcessGridSelection(pos):
	BehaviorEvents.emit_signal("OnPopGUI")
	_input_state = INPUT_STATE.cell_targetting
	var tile = Globals.LevelLoaderRef.World_to_Tile(pos)
	var tile_content = Globals.LevelLoaderRef.levelTiles[tile.x][tile.y]
	var potential_targets = []
	for obj in tile_content:
		if obj.base_attributes.has("destroyable") || obj.base_attributes.has("harvestable"):
			potential_targets.push_back(obj)
	if potential_targets.size() == 1:
		#TODO: pass the right data for the weapon
		#TODO: Check if player has an equiped weapon
		var weapon_json = playerNode.base_attributes.mounts.small_weapon_mount
		var weapon_data = Globals.LevelLoaderRef.LoadJSON(weapon_json)
		BehaviorEvents.emit_signal("OnDealDamage", tile_content[0], playerNode, weapon_data)
	elif potential_targets.size() == 0:
		BehaviorEvents.emit_signal("OnLogLine", "There's nothing there sir...")
		_input_state = INPUT_STATE.hud
	else:
		#TODO: choose target popup dialog
		pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
