extends AnimationPlayer

func _ready():
	BehaviorEvents.connect("OnMovement", self, "OnMovement_Callback")
	#self.root_node = "../.."

func OnMovement_Callback(obj, dir):
	if obj.get_attrib("type") != "player":
		return
	if obj != self.get_parent().get_parent():
		return
	
	# Float impresision means it's not always exactly the angle we expect, 44.9999 instead of 45 for example.
	var cur_heading = Vector2(0.0, -1.0).rotated(get_node(root_node).get_parent().rotation)
	var desired_rot : float = cur_heading.angle_to(dir)
	var rot_deg = rad2deg(desired_rot)
	
	if rot_deg <= -175.0:
		self.play("rot_neg_180")
	elif rot_deg <= -125.0:
		self.play("rot_neg_135")
	elif rot_deg <= -85.0:
		self.play("rot_neg_90")
	elif rot_deg <= -40.0:
		self.play("rot_neg_45")
	elif rot_deg >= 175.0:
		self.play("rot_180")
	elif rot_deg >= 125.0:
		self.play("rot_135")
	elif rot_deg >= 85.0:
		self.play("rot_90")
	elif rot_deg >= 40.0:
		self.play("rot_45")
		
	if rot_deg >= 5.0 or rot_deg <= -5.0:
		print("WAIT FOR ANIM")
		BehaviorEvents.emit_signal("OnWaitForAnimation")
		
func OnAnimationDone_Callback(offset_deg):
	get_node(root_node).get_parent().rotation += deg2rad(offset_deg)
	get_node(root_node).rotation = 0
	
	print("ANIM DONE")
	BehaviorEvents.emit_signal("OnAnimationDone")
	