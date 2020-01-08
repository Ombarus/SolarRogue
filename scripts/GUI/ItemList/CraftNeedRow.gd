extends "res://scripts/GUI/ItemList/DefaultRow.gd"

# {"color":"red", "src":"data/json/bleh.json", "type":"optional", "count":1, "missing":false, "dragdrop_id":"Using"}
func set_row_data(data):
	var bbcode_start = ""
	var bbcode_end = ""
	var count_str = ""
	var main_text = ""
	var missing_text = ""
	if "color" in data:
		bbcode_start += "[color=" + data.color + "]"
		bbcode_end += "[/color]"
	if "count" in data and data.count > 1:
		count_str += str(data.count) + "x "
	if "type" in data:
		main_text = data.type
	elif "src" in data:
		var d = Globals.LevelLoaderRef.LoadJSON(data.src)
		main_text += Globals.mytr(d.name_id)
	if "missing" in data and data.missing == true:
		self.disabled = true
		missing_text += Globals.mytr("Missing ")
	get_node("HBoxContainer/RichTextLabel").bbcode_text = bbcode_start + missing_text + count_str + main_text + bbcode_end
	_metadata = data
	_metadata["self"] = self

func get_drag_data(position):
	if "missing" in _metadata and _metadata.missing == true:
		return null
		
	return .get_drag_data(position)