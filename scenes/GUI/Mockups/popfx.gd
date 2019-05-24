extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("flicker").connect("mouse_entered", self, "_on_mouse_enter")
	get_node("flicker").connect("mouse_exited", self, "_on_mouse_exit")
	
	
func _on_mouse_enter():
	get_node("flicker/AnimationPlayer").play("popin")

func _on_mouse_exit():
	get_node("flicker/AnimationPlayer").play_backwards("popin")
