extends Node2D

var click_start_pos : Vector2
var enable_goto := true

func _ready():
	BehaviorEvents.connect("OnCameraDragged", self, "OnCameraDragged_Callback")
	BehaviorEvents.connect("OnPlayerInputStateChanged", self, "OnPlayerInputStateChanged_Callback")
	
func OnPlayerInputStateChanged_Callback(playerObj, inputState):
	if inputState == Globals.INPUT_STATE.hud:
		enable_goto = true
	else:
		enable_goto = false

func OnCameraDragged_Callback():
	self.visible = false
	
func normalize_deg(var deg : float) -> float:
	var turns := deg / 180.0
	var whole := floor(turns)
	 
	return 180.0 * (turns-whole)
	
func _input(event):
	if event is InputEventScreenTouch:
		self.visible == false # For some reason this doesn't work here ?!?
		self.set_process_input(false)
		return
		
	if event is InputEventMouseMotion:
		var world_mouse_tile = Globals.LevelLoaderRef.World_to_Tile(get_global_mouse_position())
		var tile_world_center = Globals.LevelLoaderRef.Tile_to_World(world_mouse_tile)
		self.position = tile_world_center
		
	if event is InputEventMouseButton:
		if event.is_action_pressed("touch") and enable_goto == true:
			click_start_pos = event.position
			var player := Globals.get_first_player()
			if player == null:
				return
			var mouse_pos : Vector2 = Globals.LevelLoaderRef.World_to_Tile(get_global_mouse_position())
			var player_pos : Vector2 = Globals.LevelLoaderRef.World_to_Tile(player.position)
			
			var dir : Vector2 = mouse_pos - player_pos
			var angle : float = dir.angle_to(Vector2(-1.0, 0.0))
			get_node("targetting/GotoArrow").rotation = -angle
			get_node("targetting/AnimationPlayer").play("goto")
		else:
			self.visible = true
			get_node("targetting/AnimationPlayer").play("idle")

func _process(delta):
	if self.is_processing_input() == false:
		self.visible = false