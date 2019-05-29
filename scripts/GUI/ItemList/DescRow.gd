extends "res://scripts/GUI/ItemList/DefaultRow.gd"

export(Theme) var normal_theme = preload("res://data/theme/default_ui_text.tres")
export(Theme) var header_theme = preload("res://data/theme/header_ui_text.tres")

onready var _name = get_node("HBoxContainer/Name")
onready var _split = get_node("HBoxContainer/Split")
onready var _value = get_node("HBoxContainer/Value")
onready var _spacer = get_node("Spacer")
onready var _indent = get_node("HBoxContainer/Indent")

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
		_spacer.visible = true
		_indent.visible = false
	else:
		self.theme = normal_theme
		_value.text = data.value
		_split.visible = true
		_value.visible = true
		_spacer.visible = false
		_indent.visible = true
