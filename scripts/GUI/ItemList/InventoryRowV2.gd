extends "res://scripts/GUI/ItemList/DefaultSelectableRow.gd"

export(Theme) var normal_theme = preload("res://data/theme/default_ui_text.tres")
export(Theme) var header_theme = preload("res://data/theme/header_ui_text.tres")

#func _ready():
#	var data = {"icon": { "texture":"data/textures/space-sprite.png", "region":[256,128,128,128] }, "name_id":"Matter-to-Energy Converter MK2", "equipped":false, "header":true}
#	set_row_data(data)

# data = {"icon": { "texture":<path>, "region":[x,y,w,h] }, "name_id":<name>, "equipped":false, "header":false}
func set_row_data(data):
	get_node("Equipped").visible = data.equipped
	get_node("HBoxContainer/Wrap/Name").bbcode_text = data.name_id
	
	var icon_path : String = Globals.get_data(data, "icon.texture")
	if icon_path != null and icon_path != "":
		icon_path = Globals.clean_path(icon_path)
		var icon_region : Array = Globals.get_data(data, "icon.region")
		var t := AtlasTexture.new()
		t.atlas = load(icon_path)
		if icon_region != null:
			t.region = Rect2(icon_region[0], icon_region[1], icon_region[2], icon_region[3])
		get_node("HBoxContainer/Icon").texture = t
	else:
		get_node("HBoxContainer/Icon").texture = null
		
	if "header" in data and data.header == true:
		#TODO: If I ever have a button here it should be disabled and invisible for header rows
		self.theme = header_theme
		get_node("HBoxContainer/Icon").visible = false
		get_node("Equipped").visible = false
	else:
		self.theme = normal_theme
		get_node("HBoxContainer/Icon").visible = true

