extends Node2D

export(bool) var active = false setget set_active
export(float) var ttl = 1.0
export(float) var speed = 100.0
export(Vector2) var target = Vector2(0.0, 0.0)
export(Vector2) var rand_speed = Vector2(0.0, 0.0)
export(Vector2) var rand_offset_x = Vector2(0.0, 0.0)
export(Vector2) var rand_offset_y = Vector2(0.0, 0.0)

var _cur_time = 0
var _ttl = ttl
var _origin = Vector2(0.0, 0.0)
var _increment = Vector2(1.0, 0.0)
var _actual_speed = speed
var _random_offset : Vector2
var _delete_me = false

func set_active(newval):
	active = newval
	if active == false:
		self.position.x = 0
		_cur_time = 0
		_ttl = ttl
		
func Start(t):
	var x : float = (float(MersenneTwister.rand((rand_offset_x.y - rand_offset_x.x) * 1000)) / 1000.0) + rand_offset_x.x
	var y : float = (float(MersenneTwister.rand((rand_offset_y.y - rand_offset_y.x) * 1000)) / 1000.0) + rand_offset_y.x
	_random_offset = Vector2(x, y)
	self.global_position += _random_offset
	
	_origin = self.global_position
	target = t+_random_offset
	_cur_time = 0
	active = true
	_delete_me = false
	get_node("root").set_reset(true)
	_ttl = ttl
	var speed_offset : float = (float(MersenneTwister.rand((rand_speed.y - rand_speed.x) * 1000)) / 1000.0) + rand_speed.x
	_actual_speed = speed + speed_offset
	if target != null:
		var dir = target - _origin
		#var angle = Vector2(0.0, 0.0).angle_to_point(dir)
		#self.rotation = angle
		var dist = dir.length()
		_increment = dir / dist
		_ttl = dist / _actual_speed


func _process(delta):
	if active == false and _delete_me == true:
		_cur_time += delta
		if _cur_time >= ttl:
			get_parent().remove_child(self)
			queue_free()
			
	if active == false:
		return
		
	_cur_time += delta
		
	var move = _increment * _actual_speed * delta
	position = position + move
	
	if _cur_time >= _ttl:
		active = false
		visible = false
		_delete_me = true
		_cur_time = 0
		BehaviorEvents.emit_signal("OnAnimationDone")
		#get_parent().remove_child(self)
		#queue_free()
