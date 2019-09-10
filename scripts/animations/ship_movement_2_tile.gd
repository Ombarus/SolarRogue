extends AnimationPlayer

func _ready():
	BehaviorEvents.connect("OnMovement", self, "OnMovement_Callback")

func OnMovement_Callback(obj, dir):
	if obj.get_attrib("type") != "player":
		return
	
	# implement movement base on local ship coordinate (move_11, move_01, move_-10, etc.)
	
	#convert dir into local dir (consider current rotation of ship)
	var root : Node2D = get_node("../..")
	var root_rot_deg : float = rad2deg(root.rotation)
	var local_dir = dir.rotated(-root.rotation)
	var anim_to_play = "move_"
	if (abs(root_rot_deg) > 40.0 and abs(root_rot_deg) < 50.0) or (abs(root_rot_deg) > 130.0 and abs(root_rot_deg) < 140.0):
		anim_to_play += "diag_"
		
	var x : int = round(local_dir.x)
	var y : int = round(local_dir.y)
	
	if x == 1 and y >= 1:
		anim_to_play += "11"
	if x == 0 and y >= 1:
		anim_to_play += "01"
	if x >= 1 and y == 0:
		anim_to_play += "10"
	if x <= -1 and y >= 1:
		anim_to_play += "-11"
	if x <= -1 and y == 0:
		anim_to_play += "-10"
	if x <= -1 and y <= -1:
		anim_to_play += "-1-1"
	if x == 0 and y <= -1:
		anim_to_play += "0-1"
	if x >= 1 and y <= -1:
		anim_to_play += "1-1"
	
	self.play(anim_to_play)
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	
	
func OnAnimDone_Callback(var turn_deg : float):
	var root : Node2D = get_node("../..")
	root.position += get_node(root_node).position.rotated(root.rotation)
	root.rotation += deg2rad(turn_deg)
	get_node(root_node).rotation = 0
	get_node(root_node).position = Vector2(0,0)
	BehaviorEvents.emit_signal("OnAnimationDone")