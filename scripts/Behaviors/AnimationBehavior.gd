extends Node

var _wait_for_anim = false

# animation data be like : {"obj":self, "func":"func_name", "params":[], "priority":4}
var _animation_stack : Array = []

func _ready():
	BehaviorEvents.connect("OnShotFired", self, "OnShotFired_Callback")
	BehaviorEvents.connect("OnObjectDestroyed", self, "OnObjectDestroyed_Callback")
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAddToAnimationQueue", self, "OnAddToAnimationQueue_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	BehaviorEvents.connect("OnDamageTaken", self, "OnDamageTaken_Callback")
	
func OnWaitForAnimation_Callback():
	_wait_for_anim = true
	
func OnAnimationDone_Callback():
	_wait_for_anim = false
	if not _animation_stack.empty():
		var data = _animation_stack.pop_front()
		data["callback_obj"].callv(data["callback_name"], data["args"])
		# because lots of animations do call_deferred, have to wait a frame to make sure
		# the callback didn't lock for another animation
		if not _animation_stack.empty() and _wait_for_anim == false:
			call_deferred("_check_next_stack")
			
func _check_next_stack():
	if not _animation_stack.empty() and _wait_for_anim == false:
		var data = _animation_stack.pop_front()
		data["callback_obj"].callv(data["callback_name"], data["args"])
		if not _animation_stack.empty() and _wait_for_anim == false:
			call_deferred("_check_next_stack")
	
func OnAddToAnimationQueue_Callback(callback_obj : Node, callback_name : String, args, priority : int):
	if _wait_for_anim == false:
		callback_obj.callv(callback_name, args)
	else:
		var index = 0
		for callback in _animation_stack:
			if priority < callback["priority"]:
				break
			else:
				index += 1
		_animation_stack.insert(index, {"callback_obj":callback_obj, "callback_name":callback_name, "args":args, "priority":priority})
	
	
func OnDamageTaken_Callback(target, shooter, damage_type):
	
	if _wait_for_anim == true:
		BehaviorEvents.emit_signal("OnAddToAnimationQueue", self, "OnDamageTaken_Callback", [target, shooter, damage_type], 250)
		return

	var hit_root : Node = target.find_node("hit_fx", true, false)
	if hit_root != null:
		if damage_type == Globals.DAMAGE_TYPE.shield_hit:
			hit_root.play_shield_hit()
		elif damage_type == Globals.DAMAGE_TYPE.radiation:
			hit_root.play_radiation_hit()
		elif damage_type == Globals.DAMAGE_TYPE.healing:
			#TODO: Add some healing sfx / animation ?
			pass
		else:
			hit_root.play_hull_hit()
	
func OnObjectDestroyed_Callback(obj):
	var destroyed_scene = obj.get_attrib("animation.destroyed")
	if destroyed_scene == null:
		return
	
	#if _wait_for_anim == true:
	#	print("destroyed : waiting")
	#	BehaviorEvents.emit_signal("OnAddToAnimationQueue", self, "OnObjectDestroyed_Callback", [obj], 250)
	#	return
	
	destroyed_scene = Globals.clean_path(destroyed_scene)
	
	var scene = load(destroyed_scene)
	var n = scene.instance()
	var pos = obj.position
	n.position = pos
	var r = get_node("/root/Root/GameTiles")
	BehaviorEvents.emit_signal("OnAddToAnimationQueue", self, "call_deferred", ["safe_start", n, r, pos], 250)
	#call_deferred("safe_start", n, r, pos)

	
func OnShotFired_Callback(shot_tile, shooter, weapon):
	if not "animation" in weapon or not "shoot" in weapon.animation:
		return
		
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	var shoot_anim_scene = Globals.clean_path(weapon.animation.shoot)
	
	var scene = load(shoot_anim_scene)
	var n : Node2D = scene.instance()
	var pos = shooter.position
	n.position = pos
	var r = get_node("/root/Root/GameTiles")
	call_deferred("safe_start", n, r, Globals.LevelLoaderRef.Tile_to_World(shot_tile))
	
	if _wait_for_anim == true:
		BehaviorEvents.emit_signal("OnAddToAnimationQueue", self, "play_hit_fx", [shot_tile, shooter, weapon], 200)
	else:
		play_hit_fx(shot_tile, shooter, weapon)
	
	
	
func play_hit_fx(shot_tile, shooter, weapon):
	var hit_anim : String = Globals.get_data(weapon, "animation.hit", "")
	if hit_anim == "":
		return
	
	var area_size : int = Globals.get_data(weapon, "weapon_data.area_effect", 0.5)
	var scene = load(Globals.clean_path(hit_anim))
	var n = scene.instance()
	var pos = Globals.LevelLoaderRef.Tile_to_World(shot_tile)
	n.position = pos
	n.scale.x = n.scale.x * (2.0 * area_size)
	n.scale.y = n.scale.y * (2.0 * area_size)
	var r = get_node("/root/Root/GameTiles")
	call_deferred("safe_start", n, r, pos)
	
func safe_start(n, r, target_pos):
	r.add_child(n)
	n.Start(target_pos)
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
