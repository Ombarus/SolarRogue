extends Node2D

export(Rect2) var region_override

func _ready():
	$overlay.region_rect = region_override

func play_hull_hit():
	$AnimationPlayer.play("blink_hit")

func play_shield_hit():
	$AnimationPlayer.play("shield_hit")

func play_radiation_hit():
	$AnimationPlayer.play("radiation_hit")
	
func play_emp_hit():
	$AnimationPlayer.play("emp_hit")
