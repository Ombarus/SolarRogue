extends Node2D

export(float) var ttl = 1.0
export(float) var arc_deg = 180.0
export(Vector2) var rand_offset_x = Vector2(0.0, 0.0)
export(Vector2) var rand_offset_y = Vector2(0.0, 0.0)

var _active = false
var _target = Vector2(0.0, 0.0)
var _radial_speed_deg = 0.0
var _cur_time = 0.0
var _orig_vec = Vector2(0.0, 0.0)
var _center = Vector2(0.0, 0.0)
var _random_offset : Vector2

const DEBUG = false

func _ready():
	_radial_speed_deg = arc_deg / ttl
	
func _unhandled_input(event):
	if DEBUG == false:
		return
		
	if event is InputEventMouseButton:
		if event.is_action_released("touch"):
			var click_pos = get_global_mouse_position()
			Start(click_pos)
			
	
func Start(target):
	_active = true
	get_node("body_root/Sprite/AnimationPlayer").play("moving")
	
	var x : float = (float(MersenneTwister.rand((rand_offset_x.y - rand_offset_x.x) * 1000, false)) / 1000.0) + rand_offset_x.x
	var y : float = (float(MersenneTwister.rand((rand_offset_y.y - rand_offset_y.x) * 1000, false)) / 1000.0) + rand_offset_y.x
	_random_offset = Vector2(x, y)
	
	_target = target + _random_offset
	var dir = _target - position
	_orig_vec = dir / 2.0
	_center = position + _orig_vec
	
	_cur_time = 0.0

func _process(delta):
	if _active == false:
		return
		
	_cur_time += delta
	
	var cur_angle_deg = _cur_time * _radial_speed_deg
	var cur_vec = _orig_vec.rotated(deg2rad(cur_angle_deg))
	var t_vec = cur_vec.tangent()
	var angle = Vector2(0.0, 0.0).angle_to_point(t_vec) - deg2rad(90.0)
	var new_pos = _center - cur_vec
	position = new_pos
	rotation = angle
	
	if _cur_time >= ttl:
		_cur_time = 0
		position = _center - _orig_vec
		rotation = 0
		_active = false
		if DEBUG != true:
			BehaviorEvents.emit_signal("OnAnimationDone")
			get_parent().remove_child(self)
			queue_free()
