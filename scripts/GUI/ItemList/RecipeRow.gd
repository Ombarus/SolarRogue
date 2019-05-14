extends "res://scripts/GUI/ItemList/DefaultRow.gd"

onready var checkbox = get_node("HBoxContainer/CheckBox")

func set_row_data(data):
	get_node("HBoxContainer/RichTextLabel").bbcode_text = data.text
	_metadata = data
	if _metadata.group != null:
		checkbox.group = _metadata.group

func get_row_data():
	_metadata["selected"] = checkbox.pressed
	return _metadata

func _ready():
	connect("pressed", self, "pressed_callback")
	
func pressed_callback():
	if checkbox.group == null:
		checkbox.pressed = !checkbox.pressed
	else:
		checkbox.pressed = true
