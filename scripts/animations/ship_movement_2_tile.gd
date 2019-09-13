extends AnimationPlayer

func _ready():
	BehaviorEvents.connect("OnMovement", self, "OnMovement_Callback")
	
func normalize_deg(var deg : float) -> float:
	var turns := deg / 180.0
	var whole := floor(turns)
	 
	return 180.0 * (turns-whole)

func OnMovement_Callback(obj, dir):
	var root : Node2D = get_node("../..")
	if obj != root:
		return
	
	#convert dir into local dir (consider current rotation of ship)
	var is_diag : bool = false
	var root_rot_deg : float = normalize_deg(rad2deg(root.rotation))
	var local_dir : Vector2 = dir.rotated(-root.rotation)
	var anim_to_play = "move_"
	if (abs(root_rot_deg) > 40.0 and abs(root_rot_deg) < 50.0) or (abs(root_rot_deg) > 130.0 and abs(root_rot_deg) < 140.0):
		is_diag = true
		anim_to_play += "diag_"
		
	var x : float = local_dir.x
	var y : float = local_dir.y
	
	if (not is_diag and x >= 0.9 and y >= 0.9) or (is_diag and x >= 1.4 and abs(y) <= 0.1):
		anim_to_play += "11"
	if (not is_diag and abs(x) <= 0.1 and y >= 0.9) or (is_diag and x >= 0.7 and y >= 0.7):
		anim_to_play += "01"
	if (not is_diag and x >= 0.9 and abs(y) <= 0.1) or (is_diag and x >= 0.7 and y <= -0.7):
		anim_to_play += "10"
	if (not is_diag and x <= -0.9 and y >= 0.9) or (is_diag and abs(x) <= 0.1 and y >= 1.4):
		anim_to_play += "-11"
	if (not is_diag and x <= -0.9 and abs(y) <= 0.1) or (is_diag and x <= -0.7 and y >= 0.7):
		anim_to_play += "-10"
	if (not is_diag and x <= -0.9 and y <= -0.9) or (is_diag and x <= -1.4 and abs(y) <= 0.1):
		anim_to_play += "-1-1"
	if (not is_diag and abs(x) <= 0.1 and y <= -0.9) or (is_diag and x <= -0.7 and y <= -0.7):
		anim_to_play += "0-1"
	if (not is_diag and x >= 0.9 and y <= -0.9) or (is_diag and abs(x) <= 0.1 and y <= -1.4):
		anim_to_play += "1-1"
	
	#print("play anim " + anim_to_play)
	self.play(anim_to_play)
	root.set_attrib("animation.in_movement", true)
	#BehaviorEvents.emit_signal("OnWaitForAnimation")
	
	
func OnAnimDone_Callback(var turn_deg : float):
	var root : Node2D = get_node("../..")
	root.position += get_node(root_node).position.rotated(root.rotation)
	# I'm worried that the animation will eventually "drift" (because of floating point) away from the center of the Tiles
	# These 3 lines should prevent that
	var tile : Vector2 = Globals.LevelLoaderRef.World_to_Tile(root.position)
	root.position = Globals.LevelLoaderRef.Tile_to_World(tile)
	root.rotation += deg2rad(turn_deg)
	get_node(root_node).rotation = 0
	get_node(root_node).position = Vector2(0,0)
	root.set_attrib("animation.in_movement", false)
	BehaviorEvents.emit_signal("OnPositionUpdated", root)
	if root.get_attrib("animation.waiting_moving") == true:
		BehaviorEvents.emit_signal("OnAnimationDone")
