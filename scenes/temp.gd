tool
extends Sprite

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	get_node("../RichTextLabel").set_text(tr("TEST"))
	pass

func _input(event):
	if event.is_action_pressed("zoom_in"):
		get_node("../Camera2D").zoom -= Vector2(0.1, 0.1)
	if event.is_action_pressed("zoom_out"):
		get_node("../Camera2D").zoom += Vector2(0.1, 0.1)
	var cur_zoom = get_node("../Camera2D").zoom
	self.material.set_shader_param("zoom",cur_zoom)

func _process(delta):
	var cur_zoom = get_node("../Camera2D").zoom
	self.material.set_shader_param("zoom",cur_zoom)
