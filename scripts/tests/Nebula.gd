extends Node2D

func _process(delta):
	var t = get_viewport().canvas_transform
	#print(t)
	$TileMap.material.set_shader_param("camera_view", t)

