extends Node2D

export(float) var speed := 100.0
export(Vector2) var rand_offset_x := Vector2(0.0, 0.0)
export(Vector2) var rand_offset_y := Vector2(0.0, 0.0)

var _delete_me := false
var _started := false
var _cur_time := 0.0
var _dir : Vector2

func Start(t):
	var x : float = (float(MersenneTwister.rand((rand_offset_x.y - rand_offset_x.x) * 1000, false)) / 1000.0) + rand_offset_x.x
	var y : float = (float(MersenneTwister.rand((rand_offset_y.y - rand_offset_y.x) * 1000, false)) / 1000.0) + rand_offset_y.x
	var random_offset = Vector2(x, y)
	self.global_position += random_offset
	
	#_origin = self.global_position
	var target = t+random_offset
	_cur_time = 0
	if target != null:
		_dir = target - self.global_position
		var dist = _dir.length()
		_cur_time = dist / speed
		_dir = _dir.normalized()
		_started = true
	#	_ttl = dist / _actual_speed

func _process(delta):
	if not _started:
		return
		
	if _delete_me == true and $AudioStreamPlayer2D.playing == false:
		_cur_time += delta
		get_parent().remove_child(self)
		queue_free()
	elif _delete_me == true:
		return
			
	_cur_time -= delta
		
	var move : Vector2 = _dir * delta * speed
	position = position + move
	
	if _cur_time <= 0:
		visible = false
		_delete_me = true
		_cur_time = 0
		BehaviorEvents.emit_signal("OnAnimationDone")
