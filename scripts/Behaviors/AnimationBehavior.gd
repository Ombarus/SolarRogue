extends Node

var _wait_for_anim = false

func _ready():
	BehaviorEvents.connect("OnShotFired", self, "OnShotFired_Callback")
	BehaviorEvents.connect("OnObjectDestroyed", self, "OnObjectDestroyed_Callback")
	BehaviorEvents.connect("OnWaitForAnimation", self, "OnWaitForAnimation_Callback")
	BehaviorEvents.connect("OnAnimationDone", self, "OnAnimationDone_Callback")
	
func OnWaitForAnimation_Callback():
	_wait_for_anim = true
	
func OnAnimationDone_Callback():
	_wait_for_anim = false
	
func OnObjectDestroyed_Callback(obj):
	var destroyed_scene = obj.get_attrib("animation.destroyed")
	if destroyed_scene == null:
		return
	
	if not "res://" in destroyed_scene:
		destroyed_scene = "res://" + destroyed_scene
	
	var scene = load(destroyed_scene)
	if _wait_for_anim == true:
		yield(BehaviorEvents, "OnAnimationDone")
	var n = scene.instance()
	var pos = obj.position
	n.position = pos
	var r = get_node("/root/Root/GameTiles")
	call_deferred("safe_start", n, r, pos)
	#r.call_deferred("add_child", n)
	#n.Start(pos)
	
	
func OnShotFired_Callback(shot_tile, shooter, weapon):
	if not "animation" in weapon or not "shoot" in weapon.animation:
		return
		
	BehaviorEvents.emit_signal("OnWaitForAnimation")
	var shoot_anim_scene = weapon.animation.shoot
	if not "res://" in shoot_anim_scene:
		shoot_anim_scene = "res://" + shoot_anim_scene
	
	var scene = load(shoot_anim_scene)
	var n = scene.instance()
	var pos = shooter.position
	n.position = pos
	var r = get_node("/root/Root/GameTiles")
	call_deferred("safe_start", n, r, Globals.LevelLoaderRef.Tile_to_World(shot_tile))
	#r.call_deferred("add_child", n)
	#n.Start(target.global_position)
	
func safe_start(n, r, target_pos):
	r.add_child(n)
	n.Start(target_pos)
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
