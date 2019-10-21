extends Node2D

export(Rect2) var region_override

func _ready():
	get_node("overlay").region_rect = region_override

func play_hull_hit():
	get_node("AnimationPlayer").play("blink_hit")
