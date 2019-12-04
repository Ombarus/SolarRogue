extends Node2D

func play_hull_hit():
	get_node("Sprite/AnimationPlayer").play("boom")
	yield(get_tree().create_timer(0.1), "timeout")
	get_node("Sprite2/AnimationPlayer").play("boom")
	yield(get_tree().create_timer(0.1), "timeout")
	get_node("Sprite3/AnimationPlayer").play("boom")
	yield(get_tree().create_timer(0.2), "timeout")
	get_node("Sprite4/AnimationPlayer").play("boom")
	yield(get_tree().create_timer(0.1), "timeout")
	get_node("Sprite5/AnimationPlayer").play("boom")
	
	
	
func play_shield_hit():
	get_node("Sprite/AnimationPlayer").play("boom")
	yield(get_tree().create_timer(0.1), "timeout")
	get_node("Sprite2/AnimationPlayer").play("boom")
	yield(get_tree().create_timer(0.1), "timeout")
	get_node("Sprite3/AnimationPlayer").play("boom")
	yield(get_tree().create_timer(0.2), "timeout")
	get_node("Sprite4/AnimationPlayer").play("boom")
	yield(get_tree().create_timer(0.1), "timeout")
	get_node("Sprite5/AnimationPlayer").play("boom")
