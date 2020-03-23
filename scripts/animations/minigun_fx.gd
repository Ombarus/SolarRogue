extends Node2D

func _ready():
	get_node("tracer").amount = get_node("tracer").amount* 3
	get_node("tracer").lifetime = get_node("tracer").lifetime* 3
