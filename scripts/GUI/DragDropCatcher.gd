extends "res://scripts/GUI/Audio/ToggleBtnAudio.gd"

export(NodePath) var forward_to = null

var _node : Node = null

func _ready():
	if forward_to != null:
		_node = get_node(forward_to)
	#._ready()

func get_drag_data(position):
	if _node == null:
		return null
	return _node.call("get_drag_data", position)
	
	
func can_drop_data(position, data):
	if _node == null:
		return false
	return _node.call("can_drop_data", position, data)
	
	
func drop_data(position, data):
	if _node == null:
		return
	_node.call("drop_data", position, data)
	
func UpdateSelection():
	_node.call("UpdateSelection")
