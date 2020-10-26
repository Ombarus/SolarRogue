extends Node2D

export(float) var ttl = 1.0
export(Vector2) var ttl_min_max = Vector2(0.3, 1.0)

var fire_sound = null

func _ready():
	return
	var original_pos = self.global_position
	while(true):
		Start(self.global_position + Vector2(1200, 0))
		yield(get_tree().create_timer(1.0), "timeout")
		self.global_position = original_pos
	
func Start(target):
	var my_tile := Vector2(0,0)
	var target_tile := Vector2(5,0)
	if Globals.LevelLoaderRef != null:
		my_tile = Globals.LevelLoaderRef.World_to_Tile(self.global_position)
		target_tile = Globals.LevelLoaderRef.World_to_Tile(target)
	var tile_dist = (target_tile-my_tile).length()
	var real_ttl : float = clamp(ttl * tile_dist, ttl_min_max.x, ttl_min_max.y)
	var dir = target_tile-my_tile
	var angle = Vector2(0.0, 0.0).angle_to_point(dir)
	self.rotation = angle
	
	var base_length = 40
	var dist = (target - self.global_position)
	var desired_scale = dist.length() / base_length
	get_node("Sprite").scale.x = desired_scale
	get_node("CPUParticles2D").emission_rect_extents.x = dist.length()
	var cpu_particle = get_node("CPUParticles2D")
	var prev_am = cpu_particle.amount
	cpu_particle.amount = desired_scale * prev_am
	self.position = self.global_position + (dist / 2.0)
	
	var charge_count : int = get_node("charge").get_child_count()
	var fire_count : int = get_node("fire").get_child_count()
	var charge_sfx_id : int = MersenneTwister.rand(charge_count)
	var fire_sfx_id : int = MersenneTwister.rand(fire_count)
	
	#print("playing %s and %s" % [get_node("charge").get_child(charge_sfx_id).name, get_node("fire").get_child(fire_sfx_id).name])
	
	get_node("charge").get_child(charge_sfx_id).play()
	fire_sound = get_node("fire").get_child(fire_sfx_id)
	get_node("fire").global_position = target
	
	yield(get_tree().create_timer(real_ttl), "timeout")
	
	if Globals.LevelLoaderRef != null: 
		call_deferred("Stop")
	
func Stop():
	get_node("Sprite").visible = false
	get_node("CPUParticles2D").emitting = false
	BehaviorEvents.emit_signal("OnAnimationDone")
	yield(get_tree().create_timer(1.0), "timeout")
	visible = false
	get_parent().remove_child(self)
	queue_free()
	
func PlayFireSound():
	if fire_sound != null:
		fire_sound.play()
	fire_sound = null
