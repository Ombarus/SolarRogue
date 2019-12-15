extends Node2D

var click_start_pos : Vector2

func _ready():
	BehaviorEvents.connect("OnCameraDragged", self, "OnCameraDragged_Callback")
	
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
		if event.is_action_pressed("touch"):
			click_start_pos = event.position
			var player := Globals.get_first_player()
			var mouse_pos : Vector2 = Globals.LevelLoaderRef.World_to_Tile(get_global_mouse_position())
			var player_pos : Vector2 = Globals.LevelLoaderRef.World_to_Tile(player.position)
			
			var dir : Vector2 = mouse_pos - player_pos
			var angle : float = dir.angle_to(Vector2(-1.0, 0.0))
			angle = rad2deg(angle)
			#angle = normalize_deg(angle)
			print(angle)
			if angle < 22 and angle >= -22: # 0
				get_node("targetting/AnimationPlayer").play("goto_w")
			if angle < 67 and angle >= 22: # 45
				get_node("targetting/AnimationPlayer").play("goto_sw")
			if angle < 112 and angle >= 67: # 90
				get_node("targetting/AnimationPlayer").play("goto_s")
			if angle < 157 and angle >= 112: # 135
				get_node("targetting/AnimationPlayer").play("goto_se")
			if angle < -113 and angle >= -158: # 225 -135
				get_node("targetting/AnimationPlayer").play("goto_ne")
			if angle < -68 and angle >= -113: # 270 -90
				get_node("targetting/AnimationPlayer").play("goto_n")
			if angle < -23 and angle >= -68: # 315 -45
				get_node("targetting/AnimationPlayer").play("goto_nw")
			if angle < -158 or angle >= 157: # 180
				get_node("targetting/AnimationPlayer").play("goto_e")
		else:
			self.visible = true
			get_node("targetting/AnimationPlayer").play("idle")

func _process(delta):
	if self.is_processing_input() == false:
		self.visible = false