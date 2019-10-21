extends Node2D

export(float) var ttl = 0.7

var _cur_time = 0.0
var _active = false

func _ready():
	if has_node("Particles2D"):
		get_node("Particles2D").emitting = true
	_cur_time = 0
	_active = true
	
func Start(target):
	if has_node("Particles2D"):
		get_node("Particles2D").emitting = true
	_cur_time = 0
	_active = true

func _process(delta):
	if _active == false:
		return
		
	_cur_time += delta
	if _cur_time >= ttl:
		_cur_time = 0
		_active = false
		#BehaviorEvents.emit_signal("OnAnimationDone")
		get_parent().remove_child(self)
		queue_free()
