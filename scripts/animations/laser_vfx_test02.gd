tool
extends Node2D

export(bool) var reset = false setget set_reset

var _origin

func set_reset(newval):
	reset = false
	_origin = self.global_position

func _ready():
	_origin = self.global_position

func _process(delta):
	var sprite = get_node("Sprite")
	var cur_pos = self.global_position
	var dir = _origin - cur_pos
	var length = dir.length()
	var sprite_base_size = sprite.texture.get_size()
	var desired_scale = length / sprite_base_size.y
	var angle = Vector2(0.0, 0.0).angle_to_point(dir)
	
	sprite.scale.y = desired_scale
	var sprite_pos = dir# / 2.0
	sprite.position = sprite_pos
	sprite.rotation = angle + deg2rad(90.0)
	
	
	
