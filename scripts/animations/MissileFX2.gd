extends Node2D

export(bool) var active = false setget set_active
export(float) var ttl = 1.0
export(float) var speed = 100.0
export(Vector2) var target = Vector2(0.0, 0.0)

var _cur_time = 0
var _ttl = ttl
var _origin = Vector2(0.0, 0.0)
var _increment = Vector2(1.0, 0.0)

func set_active(newval):
	active = newval
	if active == false:
		self.position.x = 0
		_cur_time = 0
		_ttl = ttl
		
func Start(t):
	_origin = self.global_position
	target = t
	_cur_time = 0
	active = true
	get_node("root").set_reset(true)
	_ttl = ttl
	if target != null:
		var dir = target - _origin
		#var angle = Vector2(0.0, 0.0).angle_to_point(dir)
		#self.rotation = angle
		var dist = dir.length()
		_increment = dir / dist
		_ttl = dist / speed


func _process(delta):
	if active == false:
		return
		
	_cur_time += delta
		
	var move = _increment * speed * delta
	position = position + move
	
	if _cur_time >= _ttl:
		active = false
		#get_node("root").position.x = 0
		_cur_time = 0
		get_parent().remove_child(self)
		queue_free()
