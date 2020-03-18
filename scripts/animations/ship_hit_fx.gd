extends Node2D

export(Rect2) var region_override

func _ready():
	get_node("overlay").region_rect = region_override

func play_hull_hit():
	get_node("AnimationPlayer").play("blink_hit")

func play_shield_hit():
	get_node("AnimationPlayer").play("shield_hit")

func play_radiation_hit():
	get_node("AnimationPlayer").play("radiation_hit")
