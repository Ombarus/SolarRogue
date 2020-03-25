extends Node2D

export(Vector2) var rand_offset_x = Vector2(0.0, 0.0)
export(Vector2) var rand_offset_y = Vector2(0.0, 0.0)
export(float) var ttl = 1.0

onready var _tracer = get_node("tracer")

func _ready():
	pass
	
func Start(target):
	var my_tile : Vector2 = Globals.LevelLoaderRef.World_to_Tile(self.global_position)
	var target_tile : Vector2 = Globals.LevelLoaderRef.World_to_Tile(target)
	var tile_dist = (target_tile-my_tile).length()
	_tracer.amount = get_node("tracer").amount * tile_dist
	_tracer.lifetime = get_node("tracer").lifetime * tile_dist
	var dir = target_tile-my_tile
	var angle = Vector2(0.0, 0.0).angle_to_point(dir)
	self.rotation = angle
	
	var x : float = (float(MersenneTwister.rand((rand_offset_x.y - rand_offset_x.x) * 1000, false)) / 1000.0) + rand_offset_x.x
	var y : float = (float(MersenneTwister.rand((rand_offset_y.y - rand_offset_y.x) * 1000, false)) / 1000.0) + rand_offset_y.x
	var random_offset = Vector2(x, y)
	self.global_position += random_offset
	
	yield(get_tree().create_timer(ttl), "timeout")
	
	call_deferred("Stop")
	
func Stop():
	visible = false
	BehaviorEvents.emit_signal("OnAnimationDone")
	get_parent().remove_child(self)
	queue_free()
