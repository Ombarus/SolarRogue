extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	BehaviorEvents.connect("OnDealDamage", self, "OnDealDamage_Callback")
	
func OnDealDamage_Callback(target, shooter, weapon):
	if not "animation" in weapon or not "shoot" in weapon.animation:
		return
		
	var shoot_anim_scene = weapon.animation.shoot
	if not "res://" in shoot_anim_scene:
		shoot_anim_scene = "res://" + shoot_anim_scene
	
	var scene = load(shoot_anim_scene)
	var n = scene.instance()
	var pos = shooter.position
	n.position = pos
	var r = get_node("/root/Root/GameTiles")
	r.call_deferred("add_child", n)
	n.Start(target.position)
	

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
