extends "res://scripts/GUI/ItemList/DefaultSelectableRow.gd"

func set_row_data(data):
	get_node("HBoxContainer/RichTextLabel").bbcode_text = Globals.mytr(data.name_id)
	_metadata = data
	if _metadata.group != null:
		checkbox.group = _metadata.group
