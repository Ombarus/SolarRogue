extends "res://scripts/GUI/ItemList/DefaultRow.gd"

export(Theme) var normal_theme = preload("res://data/theme/default_ui_text.tres")
export(Theme) var header_theme = preload("res://data/theme/header_ui_text.tres")

#func _ready():
#	var data = {"icon": { "texture":"data/textures/space-sprite.png", "region":[256,128,128,128] }, "name_id":"Matter-to-Energy Converter MK2", "equipped":false, "header":true}
#	set_row_data(data)

# data = {"icon": { "texture":<path>, "region":[x,y,w,h] }, "name_id":<name>, "equipped":false, "header":false}
func set_row_data(data):
	_metadata = data
	_metadata["self"] = self
	if data.group != null:
		get_node("BtnWrap/Toggle").group = data.group
		
	get_node("Equipped").visible = data.equipped
	get_node("BtnWrap/HBoxContainer/Wrap/Name").bbcode_text = data.name_id
	
	var icon_path : String = Globals.get_data(data, "icon.texture")
	if icon_path != null and icon_path != "":
		icon_path = Globals.clean_path(icon_path)
		var icon_region : Array = Globals.get_data(data, "icon.region")
		var t := AtlasTexture.new()
		t.atlas = load(icon_path)
		if icon_region != null:
			t.region = Rect2(icon_region[0], icon_region[1], icon_region[2], icon_region[3])
		get_node("BtnWrap/HBoxContainer/Icon").texture = t
	else:
		get_node("BtnWrap/HBoxContainer/Icon").texture = null
		
	if "header" in data and data.header == true:
		self.theme = header_theme
		get_node("BtnWrap/Toggle").visible = false
		get_node("BtnWrap/HBoxContainer/Icon").visible = false
		get_node("Equipped").visible = false
	else:
		self.theme = normal_theme
		get_node("BtnWrap/HBoxContainer/Icon").visible = true

func _on_Toggle_toggled(button_pressed):
	_metadata.origin.bubble_selection_changed()

################ DRAG & DROP OVERRIDE #########################

func get_row_data():
	_metadata["selected"] = get_node("BtnWrap/Toggle").pressed
	return _metadata
	
func can_drop_data(position, data):
	if not "dragdrop_id" in data or data.dragdrop_id == "":
		return false
	var res : bool = data.dragdrop_id == _metadata.dragdrop_id and data["self"].get_parent() != self.get_parent()
	if res == false:
		return res
	
	# When dropping in the "empty" list to drop an item on the floor
	if data.origin.Content.size() == 0:
		return true
		
	# Can always drop a mount anywhere in the cargo list to "remove" a mount
	if "key" in data and "idx" in data:
		return true
	
	# Sanity check, should always have a "src"
	if not "src" in data:
		return false
		
	# Dragging something from the cargo holds to a mount points... check if we can actually  mount this here	
	var json_data = Globals.LevelLoaderRef.LoadJSON(data.src)
	var slot = Globals.get_data(json_data, "equipment.slot")
	
	if slot == null or not "key" in _metadata or slot != _metadata.key:
		return false
	
	return true