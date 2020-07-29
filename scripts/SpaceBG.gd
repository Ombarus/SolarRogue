extends Node2D


export(NodePath) var cam_node;

onready var _cam = get_node(cam_node)

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _cam == null:
		return
		
	get_node("Sprite").material.set_shader_param("camera_offset", _cam.position)
