extends "res://scripts/GUI/ItemList/DefaultRow.gd"

export(Theme) var normal_theme = preload("res://data/theme/default_ui_text.tres")
export(Theme) var header_theme = preload("res://data/theme/header_ui_text.tres")

onready var _name = get_node("Name")
onready var _split = get_node("Split")
onready var _value = get_node("Value")

#func _ready():
	#var data = {"name":"Weapon mounts", "value":"1"}
	#var data = {"name":"status", "header":true}
	#set_row_data(data)

# data = {"icon": { "texture":<path>, "region":[x,y,w,h] }, "name_id":<name>, "equipped":false, "header":false}
func set_row_data(data):
	_metadata = data
	_metadata["self"] = self

	_name.text = data.name
		
	if "header" in data and data.header == true:
		self.theme = header_theme
		_split.visible = false
		_value.visible = false
	else:
		self.theme = normal_theme
		_value.text = data.value
		_split.visible = true
		_value.visible = true
