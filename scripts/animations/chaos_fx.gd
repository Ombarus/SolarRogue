extends Node2D

export(Vector2) var rand_offset_x = Vector2(0.0, 0.0)
export(Vector2) var rand_offset_y = Vector2(0.0, 0.0)
export(float) var ttl = 1.0
export(Vector2) var ttl_min_max = Vector2(0.3, 1.0)

var _dist_per_second : Vector2
#onready var _tracer = get_node("tracer")

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
	#_tracer.amount = get_node("tracer").amount * tile_dist
	#_tracer.lifetime = get_node("tracer").lifetime * tile_dist
	var dir = target_tile-my_tile
	var angle = Vector2(0.0, 0.0).angle_to_point(dir)
	self.rotation = angle
	
	var x : float = (float(MersenneTwister.rand((rand_offset_x.y - rand_offset_x.x) * 1000, false)) / 1000.0) + rand_offset_x.x
	var y : float = (float(MersenneTwister.rand((rand_offset_y.y - rand_offset_y.x) * 1000, false)) / 1000.0) + rand_offset_y.x
	var random_offset = Vector2(x, y)
	self.global_position += random_offset
	target += random_offset
	_dist_per_second = (target - self.global_position) / real_ttl
	
	yield(get_tree().create_timer(real_ttl), "timeout")
	
	if Globals.LevelLoaderRef != null: 
		call_deferred("Stop")
	
func Stop():
	_dist_per_second = Vector2(0,0)
	get_node("Sprite").visible = false
	get_node("Particles2D").emitting = false
	BehaviorEvents.emit_signal("OnAnimationDone")
	yield(get_tree().create_timer(0.5), "timeout")
	visible = false
	get_parent().remove_child(self)
	queue_free()
	
func _process(delta):
	self.global_position += _dist_per_second * delta
