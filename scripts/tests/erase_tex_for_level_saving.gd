tool
extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export(bool) var hide = false setget set_hide
export(bool) var show = false setget set_show

export(int) var gen_num = 4
export(Vector2) var start_offset = Vector2(512,0)

var _index = 0
onready var _orig_child_count = get_child_count()

func set_hide(newval):
	hide = false
	for c in self.get_children():
		if c is Sprite:
			c.texture = null
			
func set_show(newval):
	show = false
	for c in self.get_children():
		if c is Sprite:
			c._refresh()

func _process(delta):
	if _index < _orig_child_count:
		print("Processing child : ", _index, " of ", _orig_child_count)
		get_children()[_index]._refresh()
		_index += 1
	else:
		var i = _index - _orig_child_count
		print("var i = ", i)
		if i < gen_num:
			var n = get_node("Multi").duplicate()
			n.star_seed = int(randf() * 10000)
			n.position = start_offset + Vector2(i*256, 0)
			print("duplicated Multi at position ", n.position)
			n._refresh()
			self.add_child(n)
			_index += 1
