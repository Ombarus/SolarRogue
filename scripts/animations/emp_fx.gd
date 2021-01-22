extends Node2D

export(Vector2) var rand_offset_x := Vector2(0.0, 0.0)
export(Vector2) var rand_offset_y := Vector2(0.0, 0.0)

func Start(t):
	var x : float = (float(MersenneTwister.rand((rand_offset_x.y - rand_offset_x.x) * 1000, false)) / 1000.0) + rand_offset_x.x
	var y : float = (float(MersenneTwister.rand((rand_offset_y.y - rand_offset_y.x) * 1000, false)) / 1000.0) + rand_offset_y.x
	var random_offset = Vector2(x, y)
	self.global_position += random_offset
	
	$AnimationPlayer.play("boom")
	
func TriggerAnimDone():
	BehaviorEvents.emit_signal("OnAnimationDone")

func _on_AnimationPlayer_animation_finished(anim_name):
	get_parent().remove_child(self)
	queue_free()
